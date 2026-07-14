import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/models/user.dart';
import 'package:digital_khata_new/database/hive_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null) {
    _checkLoggedInUser();
  }

  Future<void> _checkLoggedInUser() async {
    final userId = await HiveService.getLoggedInUserId();
    if (userId != null) {
      final user = HiveService.getUserById(userId);
      if (user != null) {
        state = user;
      }
    }
  }

  Future<bool> register({
    required String shopName,
    required String ownerName,
    required String phone,
    required String password,
  }) async {
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
    await HiveService.saveLoginState(user.id, true);
    state = user;
    return true;
  }

  Future<bool> login(String phone, String password) async {
    final user = HiveService.getUserByPhone(phone);
    if (user != null && user.password == password) {
      await HiveService.saveLoginState(user.id, true);
      state = user;
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await HiveService.clearLoginState();
    state = null;
  }

  void setUser(User user) {
    state = user;
  }
}