import 'package:flutter/material.dart';

class AppStateNotifier extends ChangeNotifier {
  bool isDarkMode = false;
  bool _mustChangePassword = false;

  bool get mustChangePassword => _mustChangePassword;

  void updateTheme(bool isDarkMode) {
    this.isDarkMode = isDarkMode;
    notifyListeners();
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
