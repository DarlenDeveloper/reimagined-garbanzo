import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary, // POP red
    onPrimary: AppColors.white,
    secondary: AppColors.primaryLight, // Dark red
    onSecondary: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.black,
    error: AppColors.error, // POP red
  ),
  scaffoldBackgroundColor: AppColors.white,
  textTheme: GoogleFonts.poppinsTextTheme(),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.black),
    iconTheme: const IconThemeData(color: AppColors.black), // Keep icons black
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.black,
      side: const BorderSide(color: AppColors.grey300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.grey100,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.black, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: GoogleFonts.poppins(color: AppColors.grey500),
  ),
  cardTheme: const CardThemeData(
    color: AppColors.grey100,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.white,
    selectedItemColor: AppColors.black,
    unselectedItemColor: AppColors.grey500,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: AppColors.black,
    unselectedLabelColor: AppColors.grey500,
    indicatorColor: AppColors.black,
    indicatorSize: TabBarIndicatorSize.label,
    dividerColor: AppColors.grey200,
    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
    unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.white : AppColors.grey400),
    trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.black : AppColors.grey300),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? AppColors.black : AppColors.white),
    checkColor: WidgetStateProperty.all(AppColors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.grey200, thickness: 1),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.black,
    contentTextStyle: GoogleFonts.poppins(color: AppColors.white),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
);

// Keep for backward compatibility
final appTheme = lightTheme;
