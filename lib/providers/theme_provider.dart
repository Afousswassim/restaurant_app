import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const _prefsKey = 'is_dark_mode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_prefsKey) ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }
}
