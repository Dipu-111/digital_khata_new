import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/database/hive_service.dart';
import 'package:digital_khata_new/models/user.dart';

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null);
  
  Future<bool> register({
    required String shopName,
    required String ownerName,
    required String phone,
    required String password,
  }) async {
    // Check if user already exists
    final existingUser = HiveService.getUserByPhone(phone);
    if (existingUser != null) {
      return false;
    }
    
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      shopName: shopName,
      ownerName: ownerName,
      phone: phone,
      password: password,
      createdAt: DateTime.now(),
    );
    
    await HiveService.addUser(user);
    state = user;
    return true;
  }
  
  bool login(String phone, String password) {
    final user = HiveService.getUserByPhone(phone);
    if (user != null && user.password == password) {
      state = user;
      return true;
    }
    return false;
  }
  void setUser(User user) {
  state = user;
}
  
  void logout() {
    state = null;
  }
}