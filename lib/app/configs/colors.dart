import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F8FF);
  static const Color lightBackgroundHover = Color(0xFFF7F7F7);
  static const Color lightBackgroundPress = Color(0xFFEAEAEA);
  static const Color lightBorderColor = Color(0xFFE2E2E2);
  static const Color lightBorderColorHover = Color(0xFFCFCFCF);
  static const Color lightBorderColorPress = Color(0xFFB5B5B5);
  static const Color lightBorderColorFocus = Color(0xFF999999);
  static const Color lightColor = Color(0xFF000000);
  static const Color lightColorHover = Color(0xFF111111);
  static const Color lightColorPress = Color(0xFF222222);
  static const Color lightBackgroundFocus = Color(0xFFE0E0E0);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFEEEEEE);
  static const Color lightGray10 = Color(0xFF1C1C1E);
  static const Color lightGray3 = Color(0xFF333333);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextHint = Color(0xFF999999);
  static const Color lightDivider = Color(0xFFEEEEEE);
  static const Color lightShadow = Color(0x1A000000);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkBackgroundHover = Color(0xFF1A1A1A);
  static const Color darkBackgroundPress = Color(0xFF222222);
  static const Color darkBorderColor = Color(0xFF2C2C2C);
  static const Color darkBorderColorHover = Color(0xFF3A3A3A);
  static const Color darkBorderColorPress = Color(0xFF444444);
  static const Color darkBorderColorFocus = Color(0xFF555555);
  static const Color darkColor = Color(0xFFFFFFFF);
  static const Color darkColorHover = Color(0xFFF0F0F0);
  static const Color darkColorPress = Color(0xFFE0E0E0);
  static const Color darkBackgroundFocus = Color(0xFF333333);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  static const Color darkCardBorder = Color(0xFF2C2C2C);
  static const Color darkGray10 = Color(0xFFF2F2F7);
  static const Color darkGray3 = Color(0xFF8E8E93);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkTextHint = Color(0xFF6C6C6C);
  static const Color darkDivider = Color(0xFF2C2C2C);
  static const Color darkShadow = Color(0x1A000000);

  // Shared Colors
  static const Color primary = Color(0xFFFF6B6B);
  static const Color secondary = Color(0xFF4ECDC4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color colorSecondary = Color(0xFF808080);
  static const Color red2 = Color(0xFFFF3B30);
  static const Color red10 = Color(0xFFFF0000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // New theme-aware getters
  static Color get primaryColor => primary;
  static Color get primaryLightColor => primary.withOpacity(0.1);
  static Color get greenColor => const Color(0xFF57CA8C);
  static Color get redColor => const Color(0xFFFF7675);
  static Color get greyColor => const Color(0xFF9698A9);

  // Legacy but updated getters
  static Color get backgroundColor =>
      _isDarkMode ? darkBackground : lightBackground;
  static Color get whiteColor => _isDarkMode ? darkCard : Colors.white;
  static Color get purpleColor => primary;
  static Color get blackColor => _isDarkMode ? darkText : lightColor;
  static Color get blackTextColor => _isDarkMode ? darkText : lightText;
  static Color get greyTextColor =>
      _isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color get dashedLineColor => _isDarkMode ? darkDivider : lightDivider;
  static Color get backgroundColorDark => darkBackground;

  // Internal dark mode flag
  static bool _isDarkMode = false;

  static void setDarkMode(bool isDarkMode) {
    _isDarkMode = isDarkMode;
  }

  static bool get isDarkMode => _isDarkMode;
  static bool get isLightMode => !_isDarkMode;

  // Helper method to get theme-aware colors
  static Color getTextColor(bool isDarkMode) =>
      isDarkMode ? darkText : lightText;
  static Color getTextSecondaryColor(bool isDarkMode) =>
      isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color getCardColor(bool isDarkMode) =>
      isDarkMode ? darkCard : lightCard;
  static Color getCardBackgroundColor(bool isDarkMode) =>
      isDarkMode ? darkCardBackground : lightCardBackground;
  static Color getCardBorderColor(bool isDarkMode) =>
      isDarkMode ? darkCardBorder : lightCardBorder;
  static Color getBorderColor(bool isDarkMode) =>
      isDarkMode ? darkBorderColor : lightBorderColor;
  static Color getDividerColor(bool isDarkMode) =>
      isDarkMode ? darkDivider : lightDivider;
  static Color getHintTextColor(bool isDarkMode) =>
      isDarkMode ? darkTextHint : lightTextHint;
  static Color getShadowColor(bool isDarkMode) =>
      isDarkMode ? darkShadow : lightShadow;

  // Dynamic selection based on current mode
  static Color get dynamicBackground =>
      _isDarkMode ? darkBackground : lightBackground;
  static Color get dynamicCard => _isDarkMode ? darkCard : lightCard;
  static Color get dynamicText => _isDarkMode ? darkText : lightText;
  static Color get dynamicTextSecondary =>
      _isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color get dynamicBorder =>
      _isDarkMode ? darkBorderColor : lightBorderColor;
  static Color get dynamicDivider => _isDarkMode ? darkDivider : lightDivider;
}
