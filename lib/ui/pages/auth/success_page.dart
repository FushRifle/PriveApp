import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/ui/pages/auth/auth_design.dart';

class OnboardingSuccessPage extends StatefulWidget {
  const OnboardingSuccessPage({super.key});

  @override
  State<OnboardingSuccessPage> createState() => _OnboardingSuccessPageState();
}

class _OnboardingSuccessPageState extends State<OnboardingSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Auto navigate to home after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, NamedRoutes.homeScreen);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: AuthSectionCard(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) => Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 94,
                            height: 94,
                            decoration: BoxDecoration(
                              color: palette.secondary.withOpacity(
                                palette.isDark ? 0.15 : 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: palette.secondary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: palette.secondary.withOpacity(0.24),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 36,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'You’re all set',
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Clique profile is ready. Your people and moments are waiting.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 13.5,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        color: palette.primary,
                        backgroundColor: palette.inputSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Opening your home feed…',
                      style: TextStyle(
                        color: palette.subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
