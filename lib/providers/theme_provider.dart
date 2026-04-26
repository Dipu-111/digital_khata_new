import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('is_dark_mode') ?? false;
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      state = ThemeMode.light;
    }
  }
  
  Future<void> toggleTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = state == ThemeMode.dark;
      state = isDark ? ThemeMode.light : ThemeMode.dark;
      await prefs.setBool('is_dark_mode', state == ThemeMode.dark);
    } catch (e) {
      // If error, just toggle without saving
      state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
  }
  
  bool isDarkMode() {
    return state == ThemeMode.dark;
  }
}