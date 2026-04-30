import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/models/user.dart';
import 'package:digital_khata_new/services/api_service.dart';
import 'package:digital_khata_new/database/hive_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null) {
    _checkLoggedInUser();
  }

  Future<void> _checkLoggedInUser() async {
    // Check if token exists
    final token = await ApiService.getToken();
    if (token != null) {
      // Token exists, but we don't have user data
      // User will need to login again or we can stored user data
      final userId = await HiveService.getLoggedInUserId();
      if (userId != null) {
        final user = HiveService.getUserById(userId);
        if (user != null) {
          state = user;
        }
      }
    }
  }
  
  Future<bool> register({
    required String shopName,
    required String ownerName,
    required String phone,
    required String password,
  }) async {
    final response = await ApiService.register(
      shopName: shopName,
      ownerName: ownerName,
      phone: phone,
      password: password,
    );
    
    if (response['success'] == true) {
      // Save token
      if (response['token'] != null) {
        await ApiService.saveToken(response['token']);
      }
      
      // Save user to Hive
      final user = User(
        id: response['user_id'],
        shopName: shopName,
        ownerName: ownerName,
        phone: phone,
        password: password,
        createdAt: DateTime.now(),
      );
      await HiveService.addUser(user);
      await HiveService.saveLoginState(user.id, true);
      state = user;
      return true;
    }
    return false;
  }
  
  Future<bool> login(String phone, String password) async {
    final response = await ApiService.login(
      phone: phone,
      password: password,
    );
    
    if (response['success'] == true) {
      // Save token
      if (response['token'] != null) {
        await ApiService.saveToken(response['token']);
      }
      
      final userData = response['user'];
      final user = User(
        id: userData['id'],
        shopName: userData['shop_name'],
        ownerName: userData['owner_name'],
        phone: userData['phone'],
        password: password,
        createdAt: DateTime.now(),
      );
      
      await HiveService.addUser(user);
      await HiveService.saveLoginState(user.id, true);
      state = user;
      return true;
    }
    return false;
  }
  
  Future<void> logout() async {
    await ApiService.clearToken();
    await HiveService.clearLoginState();
    state = null;
  }
  
  void setUser(User user) {
    state = user;
  }
}