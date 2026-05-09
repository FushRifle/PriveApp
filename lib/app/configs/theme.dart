import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Prive/app/configs/colors.dart';

class AppTheme {
  // Dynamic text styles that adapt to theme
  static TextStyle get blackTextStyle =>
      GoogleFonts.poppins(color: AppColors.dynamicText);

  static TextStyle get whiteTextStyle =>
      GoogleFonts.poppins(color: AppColors.white);

  static TextStyle get greyTextStyle =>
      GoogleFonts.poppins(color: AppColors.dynamicTextSecondary);

  static FontWeight light = FontWeight.w300;
  static FontWeight regular = FontWeight.w400;
  static FontWeight medium = FontWeight.w500;
  static FontWeight semiBold = FontWeight.w600;
  static FontWeight bold = FontWeight.w700;
  static FontWeight extraBold = FontWeight.w800;
  static FontWeight black = FontWeight.w900;

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCard,
    dividerColor: AppColors.lightDivider,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightCard,
      error: AppColors.red2,
      onPrimary: AppColors.onPrimary,
      onSecondary: AppColors.white,
      onSurface: AppColors.lightText,
      onError: AppColors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.lightText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red2, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.poppins(
        color: AppColors.lightTextHint,
        fontSize: 14,
      ),
      errorStyle: GoogleFonts.poppins(color: AppColors.red2, fontSize: 12),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        color: AppColors.lightText,
        fontSize: 32,
        fontWeight: bold,
      ),
      displayMedium: GoogleFonts.poppins(
        color: AppColors.lightText,
        fontSize: 28,
        fontWeight: bold,
      ),
      displaySmall: GoogleFonts.poppins(
        color: AppColors.lightText,
        fontSize: 24,
        fontWeight: bold,
      ),
      headlineMedium: GoogleFonts.poppins(
        color: AppColors.lightText,
        fontSize: 20,
        fontWeight: semiBold,
      ),
      titleLarge: GoogleFonts.poppins(
        color: AppColors.lightText,
        fontSize: 18,
        fontWeight: semiBold,
      ),
      bodyLarge: GoogleFonts.poppins(color: AppColors.lightText, fontSize: 16),
      bodyMedium: GoogleFonts.poppins(color: AppColors.lightText, fontSize: 14),
      bodySmall: GoogleFonts.poppins(
        color: AppColors.lightTextHint,
        fontSize: 12,
      ),
      labelLarge: GoogleFonts.poppins(
        color: AppColors.white,
        fontSize: 16,
        fontWeight: medium,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: GoogleFonts.poppins(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: bold,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        side: const BorderSide(color: AppColors.primary),
        textStyle: GoogleFonts.poppins(
          color: AppColors.lightText,
          fontSize: 16,
          fontWeight: medium,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCard,
    dividerColor: AppColors.darkDivider,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkCard,
      error: AppColors.red2,
      onPrimary: AppColors.onPrimary,
      onSecondary: AppColors.white,
      onSurface: AppColors.darkText,
      onError: AppColors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.darkText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red2, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.poppins(
        color: AppColors.darkTextHint,
        fontSize: 14,
      ),
      errorStyle: GoogleFonts.poppins(color: AppColors.red2, fontSize: 12),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        color: AppColors.darkText,
        fontSize: 32,
        fontWeight: bold,
      ),
      displayMedium: GoogleFonts.poppins(
        color: AppColors.darkText,
        fontSize: 28,
        fontWeight: bold,
      ),
      displaySmall: GoogleFonts.poppins(
        color: AppColors.darkText,
        fontSize: 24,
        fontWeight: bold,
      ),
      headlineMedium: GoogleFonts.poppins(
        color: AppColors.darkText,
        fontSize: 20,
        fontWeight: semiBold,
      ),
      titleLarge: GoogleFonts.poppins(
        color: AppColors.darkText,
        fontSize: 18,
        fontWeight: semiBold,
      ),
      bodyLarge: GoogleFonts.poppins(color: AppColors.darkText, fontSize: 16),
      bodyMedium: GoogleFonts.poppins(color: AppColors.darkText, fontSize: 14),
      bodySmall: GoogleFonts.poppins(
        color: AppColors.darkTextHint,
        fontSize: 12,
      ),
      labelLarge: GoogleFonts.poppins(
        color: AppColors.white,
        fontSize: 16,
        fontWeight: medium,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: GoogleFonts.poppins(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: bold,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        side: const BorderSide(color: AppColors.primary),
        textStyle: GoogleFonts.poppins(
          color: AppColors.darkText,
          fontSize: 16,
          fontWeight: medium,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkCard,
      indicatorColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
  );
}

// Helper extension for easier theme access
extension ThemeHelper on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get primaryColor => AppColors.primary;
  Color get secondaryColor => AppColors.secondary;

  // Theme-aware colors
  Color get cardColor => isDarkMode ? AppColors.darkCard : AppColors.lightCard;
  Color get cardBackground =>
      isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
  Color get cardBorder =>
      isDarkMode ? AppColors.darkCardBorder : AppColors.lightCardBorder;
  Color get borderColor =>
      isDarkMode ? AppColors.darkBorderColor : AppColors.lightBorderColor;
  Color get dividerColor =>
      isDarkMode ? AppColors.darkDivider : AppColors.lightDivider;
  Color get textColor => isDarkMode ? AppColors.darkText : AppColors.lightText;
  Color get textSecondary =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textHint =>
      isDarkMode ? AppColors.darkTextHint : AppColors.lightTextHint;
}
