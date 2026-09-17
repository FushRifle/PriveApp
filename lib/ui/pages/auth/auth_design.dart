import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:clique/app/configs/colors.dart';

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
      background: isDark ? const Color(0xFF0B1118) : const Color(0xFFF4F7FA),
      surface: isDark ? const Color(0xFF121B25) : const Color(0xFFFFFFFF),
      raisedSurface: isDark ? const Color(0xFF182430) : const Color(0xFFFCFDFE),
      inputSurface: isDark ? const Color(0xFF0F1720) : const Color(0xFFF0F4F7),
      border: isDark ? const Color(0xFF2B3948) : const Color(0xFFDCE4EB),
      text: isDark ? const Color(0xFFF2F6FA) : const Color(0xFF17212B),
      muted: isDark ? const Color(0xFF9AA8B7) : const Color(0xFF607080),
      subtle: isDark ? const Color(0xFF657587) : const Color(0xFF91A0AE),
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      shadow: isDark
          ? Colors.black.withOpacity(0.24)
          : const Color(0xFF22364A).withOpacity(0.07),
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
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthPageHeading(
          title: title,
          subtitle: subtitle,
          icon: icon,
          palette: palette,
        ),
        const SizedBox(height: 18),
        if (scrollable) child else Expanded(child: child),
      ],
    );

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
        appBar: AppBar(
          backgroundColor: palette.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 56,
          leading: Navigator.canPop(context)
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: palette.text,
                  ),
                )
              : null,
          actions: actions,
        ),
        body: SafeArea(
          top: false,
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
        bottomNavigationBar: bottom,
      ),
    );
  }
}

class _AuthPageHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final AuthPalette palette;

  const _AuthPageHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.primary.withOpacity(palette.isDark ? 0.16 : 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: palette.primary, size: 21),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 25,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
