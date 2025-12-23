import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Light mode only - no dark mode
  ThemeMode get themeMode => ThemeMode.light;
  bool get isDark => false;

  void toggleTheme() {
    // No-op - light mode only
  }

  void setThemeMode(ThemeMode mode) {
    // No-op - light mode only
  }
}
