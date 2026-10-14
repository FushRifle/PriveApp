import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';

@immutable
class AuthPalette {
  final bool isDark;
  final Color background;
  final Color surface;
  final Color raisedSurface;
  final Color inputSurface;
  final Color border;
  final Color text;
  final Color muted;
  final Color subtle;
  final Color primary;
  final Color secondary;
  final Color shadow;

  const AuthPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.raisedSurface,
    required this.inputSurface,
    required this.border,
    required this.text,
    required this.muted,
    required this.subtle,
    required this.primary,
    required this.secondary,
    required this.shadow,
  });

  factory AuthPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AuthPalette(
      isDark: isDark,
      background: AppColors.background,
      surface: AppColors.card,
      raisedSurface: AppColors.cardColor,
      inputSurface: AppColors.backgroundColor,
      border: AppColors.border,
      text: AppColors.text,
      muted: AppColors.textSecondary,
      subtle: AppColors.textHint,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      shadow: AppColors.shadow,
    );
  }
}

class AuthPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottom;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  const AuthPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.actions,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 28),
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    final content = scrollable ? child : Expanded(child: child);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            palette.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            palette.isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: palette.background,
        body: Column(
          children: [
            AppPageHeader(
              title: title,
              subtitle: subtitle ?? 'Account security',
              leadingIcon:
                  Navigator.canPop(context) ? Icons.arrow_back_rounded : icon,
              onLeadingTap: Navigator.canPop(context)
                  ? () => Navigator.maybePop(context)
                  : null,
              action: actions == null
                  ? null
                  : Row(mainAxisSize: MainAxisSize.min, children: actions!),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: scrollable
                      ? SingleChildScrollView(
                          padding: padding,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: content,
                        )
                      : Padding(padding: padding, child: content),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: bottom,
      ),
    );
  }
}

class AuthSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const AuthSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withOpacity(0.72)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

InputDecoration authInputDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  IconData? icon,
  Widget? suffix,
  String? errorText,
}) {
  final palette = AuthPalette.of(context);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: palette.border),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    prefixIcon: icon == null ? null : Icon(icon, size: 19),
    suffixIcon: suffix,
    filled: true,
    fillColor: palette.inputSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    labelStyle: TextStyle(color: palette.muted, fontSize: 13),
    hintStyle: TextStyle(color: palette.subtle, fontSize: 13),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: palette.primary, width: 1.6),
    ),
    errorBorder: border.copyWith(
      borderSide: const BorderSide(color: AppColors.error),
    ),
  );
}
