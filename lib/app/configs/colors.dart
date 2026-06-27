import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F5F7);
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
  static const Color lightCard = Color(0xFFF2F2F7);
  static const Color lightCardBackground = Color(0xFFFFFFFF); // Deep white
  static const Color lightCardBorder = Color(0xFFEEEEEE);
  static const Color lightGray10 = Color(0xFF1C1C1E);
  static const Color lightGray3 = Color(0xFF333333);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextHint = Color(0xFF999999);
  static const Color lightDivider = Color(0xFFEEEEEE);
  static const Color lightShadow = Color(0x1A000000); // 10% opacity shadow
  static const Color lightShadowElevated =
      Color(0x0D000000); // 5% opacity shadow

  // Dark Theme Colors (GitHub Dark)
  static const Color darkBackground = Color(0xFF0D1117); // GitHub dark bg
  static const Color darkBackgroundHover = Color(0xFF1A1A1A);
  static const Color darkBackgroundPress = Color(0xFF222222);
  static const Color darkBorderColor = Color(0xFF30363D); // GitHub border
  static const Color darkBorderColorHover = Color(0xFF3A3A3A);
  static const Color darkBorderColorPress = Color(0xFF444444);
  static const Color darkBorderColorFocus = Color(0xFF555555);
  static const Color darkColor = Color(0xFFFFFFFF);
  static const Color darkColorHover = Color(0xFFF0F0F0);
  static const Color darkColorPress = Color(0xFFE0E0E0);
  static const Color darkBackgroundFocus = Color(0xFF333333);
  static const Color darkCard = Color(0xFF161B22); // GitHub card color
  static const Color darkCardBackground =
      Color(0xFF161B22); // GitHub card color
  static const Color darkCardBorder = Color(0xFF30363D); // GitHub border
  static const Color darkGray10 = Color(0xFFF2F2F7);
  static const Color darkGray3 = Color(0xFF8E8E93);
  static const Color darkText = Color(0xFFF0F6FC); // GitHub text
  static const Color darkTextSecondary = Color(0xFF8B949E); // GitHub secondary
  static const Color darkTextHint = Color(0xFF484F58);
  static const Color darkDivider = Color(0xFF21262D);
  static const Color darkShadow = Color(0x1A000000); // 10% opacity shadow
  static const Color darkShadowElevated =
      Color(0x33000000); // 20% opacity shadow

  // Shared Colors
  static const Color primary = Color(0xFFFF6B6B);
  static const Color secondary = Color(0xFF4ECDC4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color colorSecondary = Color(0xFF808080);
  static const Color red2 = Color(0xFFFF3B30);
  static const Color red10 = Color(0xFFFF0000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
  static const Color black87 = Colors.black87;
  static const Color black54 = Colors.black54;
  static const Color black45 = Colors.black45;
  static const Color white10 = Colors.white10;
  static const Color white24 = Colors.white24;
  static const Color white30 = Colors.white30;
  static const Color white54 = Colors.white54;
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white70 = Colors.white70;
  static const Color red = red2;
  static const Color redAccent = Color(0xFFFF5252);
  static const Color green = success;
  static const Color blue = info;
  static const Color orange = githubOrange;
  static const Color purple = githubPurple;
  static const Color pink = Color(0xFFE85D9E);
  static const Color teal = secondary;
  static const Color indigo = Color(0xFF5B6EE1);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color attachmentPurple = Color(0xFF8B5CF6);
  static const Color attachmentCyan = Color(0xFF06B6D4);
  static const Color attachmentGreen = Color(0xFF10B981);
  static const Color attachmentAmber = Color(0xFFF59E0B);
  static const Color storyTextBackground = Color(0xFF1D1B20);
  static const Color storyPurple = Color(0xFF6750A4);
  static const Color storyRed = Color(0xFFB3261E);
  static const Color storyDeepPurple = Color(0xFF21005D);
  static const Color storyTeal = Color(0xFF006A6A);
  static const Color storyMuted = Color(0xFF434948);
  static const Color storyYellow = Color(0xFFFFE66D);
  static const Color storyGreen = Color(0xFF95E77E);
  static const Color storyRingPurple = Color(0xFF833AB4);
  static const Color storyRingRed = Color(0xFFFD1D1D);
  static const Color storyRingOrange = Color(0xFFFCAF45);
  static const Color exploreHeaderText = Color(0xFF1A1A2E);
  static const Color settingsLightBackground = Color(0xFFF7F7F7);
  static const Color inputLightBackground = Color(0xFFF1F1F1);
  static const MaterialColor grey = Colors.grey;
  static const MaterialColor amber = Colors.amber;
  static const MaterialColor blueGrey = Colors.blueGrey;

  // Status colors
  static const Color success = Color(0xFF2DA44E);
  static const Color warning = Color(0xFFE3B341);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);
  static const Color githubGreen = Color(0xFF238636);
  static const Color githubRed = Color(0xFFDA3633);
  static const Color githubPurple = Color(0xFF8957E5);
  static const Color githubOrange = Color(0xFFD29922);

  // Internal dark mode flag
  static bool _isDarkMode = false;

  // ============= THEME-AWARE GETTERS ======
  static Color get background => _isDarkMode ? darkBackground : lightBackground;
  static Color get card => _isDarkMode ? darkCard : lightCard;
  static Color get cardBorder => _isDarkMode ? darkCardBorder : lightCardBorder;
  static Color get border => _isDarkMode ? darkBorderColor : lightBorderColor;
  static Color get divider => _isDarkMode ? darkDivider : lightDivider;

  static Color get text => _isDarkMode ? darkText : lightText;
  static Color get textSecondary =>
      _isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color get textHint => _isDarkMode ? darkTextHint : lightTextHint;

  static Color get shadow => _isDarkMode ? darkShadow : lightShadow;
  static Color get shadowElevated =>
      _isDarkMode ? darkShadowElevated : lightShadowElevated;

  static Color get icon => _isDarkMode ? darkTextSecondary : lightTextSecondary;

  // Status colors (always the same)
  static Color get successColor => success;
  static Color get warningColor => warning;
  static Color get errorColor => error;
  static Color get infoColor => info;

  // Legacy getters (maintain compatibility)
  static Color get backgroundColor => background;
  static Color get whiteColor => card;
  static Color get purpleColor => primary;
  static Color get blackColor => text;
  static Color get blackTextColor => text;
  static Color get greyTextColor => textSecondary;
  static Color get dashedLineColor => divider;
  static Color get backgroundColorDark => darkBackground;
  static Color get cardColor => card;
  static Color get cardBorderColor => cardBorder;
  static Color get primaryColor => primary;
  static Color get primaryLightColor => primary.withOpacity(0.1);
  static Color get greenColor => const Color(0xFF57CA8C);
  static Color get redColor => const Color(0xFFFF7675);
  static Color get greyColor => const Color(0xFF9698A9);

  // Helper methods
  static void setDarkMode(bool isDarkMode) {
    _isDarkMode = isDarkMode;
  }

  static bool get isDarkMode => _isDarkMode;
  static bool get isLightMode => !_isDarkMode;

  // Parameter-based getters (for when you need to pass theme explicitly)
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

  // Dynamic selection (maintain compatibility)
  static Color get dynamicBackground => background;
  static Color get dynamicCard => card;
  static Color get dynamicText => text;
  static Color get dynamicTextSecondary => textSecondary;
  static Color get dynamicBorder => border;
  static Color get dynamicDivider => divider;
}
