import 'package:flutter/material.dart';

class AppStateNotifier extends ChangeNotifier {
  bool isDarkMode = false;

  void updateTheme(bool isDarkMode) {
    isDarkMode = isDarkMode;
    notifyListeners();
  }
}