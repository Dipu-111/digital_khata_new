import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Check if device supports biometrics
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      return false;
    }
  }

  // Authenticate with fingerprint/face
  static Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Verify your identity to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // Save credentials after successful login
  static Future<void> saveCredentials(String phone, String password, {bool rememberMe = false}) async {
    await _storage.write(key: 'saved_phone', value: phone);
    await _storage.write(key: 'saved_password', value: password);
    await _storage.write(key: 'biometric_enabled', value: 'true');
    
    // Save remember me status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', rememberMe);
    if (rememberMe) {
      await prefs.setString('last_phone', phone);
    }
  }

  // Get saved credentials
  static Future<Map<String, String?>> getSavedCredentials() async {
    final phone = await _storage.read(key: 'saved_phone');
    final password = await _storage.read(key: 'saved_password');
    final enabled = await _storage.read(key: 'biometric_enabled');
    
    return {
      'phone': phone,
      'password': password,
      'enabled': enabled,
    };
  }

  // Clear saved credentials (on logout)
  static Future<void> clearCredentials() async {
    await _storage.delete(key: 'saved_phone');
    await _storage.delete(key: 'saved_password');
    await _storage.delete(key: 'biometric_enabled');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');
    await prefs.remove('last_phone');
  }

  // Check if biometric login is enabled
  static Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: 'biometric_enabled');
    return enabled == 'true';
  }
  
  // Check if user should stay logged in
  static Future<bool> isRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_me') ?? false;
  }
  
  // Get last logged in phone
  static Future<String?> getLastPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_phone');
  }
  
  // Save login state
  static Future<void> saveLoginState(String userId, bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', isLoggedIn);
    if (isLoggedIn) {
      await prefs.setString('user_id', userId);
    }
  }
  
  // Check if user is already logged in
  static Future<bool> isAlreadyLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }
  
  // Get logged in user ID
  static Future<String?> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
  
  // Clear login state
  static Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_id');
  }
}