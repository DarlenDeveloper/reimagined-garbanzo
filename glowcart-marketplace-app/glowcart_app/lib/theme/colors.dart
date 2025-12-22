import 'package:flutter/material.dart';

class AppColors {
  // Primary - Black & White
  static const Color primary = Color(0xFF000000);
  static const Color primaryLight = Color(0xFF333333);
  static const Color primaryDark = Color(0xFF000000);

  // Backward compatibility aliases (all map to black/grey)
  static const Color darkGreen = Color(0xFF000000);
  static const Color limeAccent = Color(0xFF000000);
  static const Color accent = Color(0xFFF5F5F5); // grey100 for accent areas

  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundBeige = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFF5F5F5);

  // Dark mode backgrounds (map to light for consistency)
  static const Color darkBackground = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFFF5F5F5);
  static const Color darkSurfaceVariant = Color(0xFFEEEEEE);

  // Text
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color darkTextPrimary = Color(0xFF000000);
  static const Color darkTextSecondary = Color(0xFF757575);

  // Borders & Dividers
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);
  static const Color darkBorder = Color(0xFFE0E0E0);

  // Input Fields
  static const Color inputFill = Color(0xFFF5F5F5);
  static const Color inputBorder = Color(0xFFE0E0E0);

  // Status (all black for consistency)
  static const Color success = Color(0xFF000000);
  static const Color warning = Color(0xFF000000);
  static const Color error = Color(0xFF000000);
  static const Color info = Color(0xFF000000);

  // Other
  static const Color favoriteActive = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
}

// Extension for easy theme-aware color access
extension ThemeColors on BuildContext {
  bool get isDark => false; // Always light mode
  
  Color get primaryColor => AppColors.primary;
  Color get backgroundColor => AppColors.background;
  Color get surfaceColor => AppColors.surface;
  Color get surfaceVariantColor => AppColors.surfaceVariant;
  Color get textPrimaryColor => AppColors.textPrimary;
  Color get textSecondaryColor => AppColors.textSecondary;
  Color get borderColor => AppColors.border;
}
