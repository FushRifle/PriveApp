import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_media_app/app/configs/colors.dart';

class AppTheme {
  static TextStyle blackTextStyle = GoogleFonts.poppins(
    color: AppColors.text,
  );

  static TextStyle whiteTextStyle = GoogleFonts.poppins(
    color: AppColors.white,
  );

  static TextStyle greyTextStyle = GoogleFonts.poppins(
    color: AppColors.colorSecondary,
  );

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
    dividerColor: AppColors.lightBorderColor,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightCard,
      error: AppColors.red2,
      onPrimary: AppColors.onPrimary,
      onSecondary: AppColors.white,
      onSurface: AppColors.lightColor,
      onError: AppColors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightColor,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: blackTextStyle.copyWith(
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
      hintStyle: greyTextStyle.copyWith(fontSize: 14),
      errorStyle: greyTextStyle.copyWith(color: AppColors.red2, fontSize: 12),
    ),
    textTheme: TextTheme(
      displayLarge: blackTextStyle.copyWith(fontSize: 32, fontWeight: bold),
      displayMedium: blackTextStyle.copyWith(fontSize: 28, fontWeight: bold),
      displaySmall: blackTextStyle.copyWith(fontSize: 24, fontWeight: bold),
      headlineMedium:
          blackTextStyle.copyWith(fontSize: 20, fontWeight: semiBold),
      titleLarge: blackTextStyle.copyWith(fontSize: 18, fontWeight: semiBold),
      bodyLarge: blackTextStyle.copyWith(fontSize: 16),
      bodyMedium: blackTextStyle.copyWith(fontSize: 14),
      bodySmall: greyTextStyle.copyWith(fontSize: 12),
      labelLarge: whiteTextStyle.copyWith(fontSize: 16, fontWeight: medium),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: whiteTextStyle.copyWith(
          fontSize: 18,
          fontWeight: bold,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        side: const BorderSide(color: AppColors.primary),
        textStyle: blackTextStyle.copyWith(
          fontSize: 16,
          fontWeight: medium,
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
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
    dividerColor: AppColors.darkBorderColor,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.darkCard,
      error: AppColors.red2,
      onPrimary: AppColors.onPrimary,
      onSecondary: AppColors.white,
      onSurface: AppColors.darkColor,
      onError: AppColors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkColor,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: whiteTextStyle.copyWith(
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
      hintStyle: greyTextStyle.copyWith(fontSize: 14),
      errorStyle: greyTextStyle.copyWith(color: AppColors.red2, fontSize: 12),
    ),
    textTheme: TextTheme(
      displayLarge: whiteTextStyle.copyWith(fontSize: 32, fontWeight: bold),
      displayMedium: whiteTextStyle.copyWith(fontSize: 28, fontWeight: bold),
      displaySmall: whiteTextStyle.copyWith(fontSize: 24, fontWeight: bold),
      headlineMedium:
          whiteTextStyle.copyWith(fontSize: 20, fontWeight: semiBold),
      titleLarge: whiteTextStyle.copyWith(fontSize: 18, fontWeight: semiBold),
      bodyLarge: whiteTextStyle.copyWith(fontSize: 16),
      bodyMedium: whiteTextStyle.copyWith(fontSize: 14),
      bodySmall: greyTextStyle.copyWith(fontSize: 12),
      labelLarge: whiteTextStyle.copyWith(fontSize: 16, fontWeight: medium),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        textStyle: whiteTextStyle.copyWith(
          fontSize: 18,
          fontWeight: bold,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        side: const BorderSide(color: AppColors.primary),
        textStyle: whiteTextStyle.copyWith(
          fontSize: 16,
          fontWeight: medium,
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.darkCard,
      indicatorColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
