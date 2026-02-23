import 'package:flutter/material.dart';

class AppColors {
  // POP Brand Colors
  static const Color primary = Color(0xFFfb2a0a); // Main red
  static const Color primaryDark = Color(0xFFb71000); // Button red
  static const Color primaryLight = Color(0xFFff5436); // Lighter red
  
  // Accent (keep for special cases)
  static const Color accent = Color(0xFFfb2a0a);
  static const Color accentLight = Color(0xFFff5436);

  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundBeige = Color(0xFFF9F9F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF9F9F9);

  // Dark Mode Backgrounds
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color darkSurface = Color(0xFF2C2C2E);
  static const Color darkSurfaceVariant = Color(0xFF3C3C3E);

  // Text - Light Mode
  static const Color textPrimary = Color(0xFF1a1a1a);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Text - Dark Mode
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Other
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFE0E0E0);
  static const Color darkBorder = Color(0xFF3C3C3E);
  static const Color favoriteActive = Color(0xFFfb2a0a);
  
  // Legacy aliases for compatibility
  static const Color darkGreen = Color(0xFFfb2a0a); // Now maps to main red
  static const Color limeAccent = Color(0xFFfb2a0a); // Now maps to main red
}

