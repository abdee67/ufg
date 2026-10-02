import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStateNotifier extends ChangeNotifier {
  static const _darkModeKey = 'isDarkMode';

  bool isDarkMode = true;
  bool _mustChangePassword = false;

  bool get mustChangePassword => _mustChangePassword;

  /// Call once at startup to restore persisted theme preference.
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool(_darkModeKey) ?? true;
    notifyListeners();
  }

  void updateTheme(bool isDarkMode) {
    this.isDarkMode = isDarkMode;
    notifyListeners();
    _persistTheme(isDarkMode);
  }

  Future<void> _persistTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  void requirePasswordChange() {
    _mustChangePassword = true;
    notifyListeners();
  }

  void clearPasswordChangeRequirement() {
    _mustChangePassword = false;
    notifyListeners();
  }
}
