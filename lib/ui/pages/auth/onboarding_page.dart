import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/named_routes.dart';

class OnboardingPage extends StatefulWidget {
  final String completionRoute;

  const OnboardingPage({
    super.key,
    this.completionRoute = NamedRoutes.loginScreen,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const String _onboardingKey = 'onboarding_completed';
  final _introKey = GlobalKey<IntroductionScreenState>();
  bool _isNavigating = false;

  late final List<PageViewModel> _pages = [
    PageViewModel(
      titleWidget: const _IntroTitle(
        title: 'Share what actually\nfeels real',
      ),
      bodyWidget: const _IntroBody(
        text:
            'Post stories, reels, and status updates that are quick to make and easy to remember.',
      ),
      image: const _IntroArtwork(
        imagePath: 'assets/images/img_post_1.jpeg',
        badge: 'Stories',
        accent: Color(0xFF6C3BD4),
      ),
      decoration: const PageDecoration(
        pageColor: Color(0xFF0F1119),
        imagePadding: EdgeInsets.only(top: 20),
        titlePadding: EdgeInsets.only(top: 20, bottom: 14),
        bodyPadding: EdgeInsets.symmetric(horizontal: 32),
        pageMargin: EdgeInsets.zero,
      ),
    ),
    PageViewModel(
      titleWidget: const _IntroTitle(
        title: 'Find your people\nfaster',
      ),
      bodyWidget: const _IntroBody(
        text:
            'Explore topics, communities, events, and people without the noise.',
      ),
      image: const _IntroArtwork(
        imagePath: 'assets/images/img_post_2.jpeg',
        badge: 'Discover',
        accent: Color(0xFF0D9488),
      ),
      decoration: const PageDecoration(
        pageColor: Color(0xFF101827),
        imagePadding: EdgeInsets.only(top: 20),
        titlePadding: EdgeInsets.only(top: 20, bottom: 14),
        bodyPadding: EdgeInsets.symmetric(horizontal: 32),
        pageMargin: EdgeInsets.zero,
      ),
    ),
    PageViewModel(
      titleWidget: const _IntroTitle(
        title: 'Keep the vibe\nmoving',
      ),
      bodyWidget: const _IntroBody(
        text:
            'React, reply, save, and jump back in wherever the conversation is still alive.',
      ),
      image: const _IntroArtwork(
        imagePath: 'assets/images/img_post_3.jpeg',
        badge: 'Connect',
        accent: Color(0xFFE74C3C),
      ),
      decoration: const PageDecoration(
        pageColor: Color(0xFF12111A),
        imagePadding: EdgeInsets.only(top: 20),
        titlePadding: EdgeInsets.only(top: 20, bottom: 14),
        bodyPadding: EdgeInsets.symmetric(horizontal: 32),
        pageMargin: EdgeInsets.zero,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    if (_isNavigating) return;
    _isNavigating = true;

    HapticFeedback.mediumImpact();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, widget.completionRoute);
  }

  void _skipToEnd() {
    HapticFeedback.lightImpact();
    _introKey.currentState?.skipToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1119),
      body: IntroductionScreen(
        key: _introKey,
        pages: _pages,
        globalBackgroundColor: const Color(0xFF0F1119),
        showSkipButton: true,
        showBackButton: false,
        showNextButton: true,
        showDoneButton: true,
        skip: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Skip',
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        next: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        done: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            'Get started',
            style: AppTheme.whiteTextStyle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        onDone: _completeOnboarding,
        onSkip: _skipToEnd,
        curve: Curves.easeOutCubic,
        dotsDecorator: DotsDecorator(
          size: const Size.square(6),
          activeSize: const Size(24, 6),
          activeColor: AppColors.primary,
          color: Colors.white.withOpacity(0.15),
          spacing: const EdgeInsets.symmetric(horizontal: 4),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        controlsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        nextFlex: 0,
      ),
    );
  }
}

class _IntroTitle extends StatelessWidget {
  final String title;

  const _IntroTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: AppTheme.whiteTextStyle.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.15,
        ),
      ),
    );
  }
}

class _IntroBody extends StatelessWidget {
  final String text;

  const _IntroBody({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.greyTextStyle.copyWith(
          color: Colors.white.withOpacity(0.65),
          fontSize: 16,
          height: 1.6,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _IntroArtwork extends StatelessWidget {
  final String imagePath;
  final String badge;
  final Color accent;

  const _IntroArtwork({
    required this.imagePath,
    required this.badge,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 0.88,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.2),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: accent.withOpacity(0.1),
                blurRadius: 48,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
                // Gradient overlay
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.4, 0.75, 1.0],
                    ),
                  ),
                ),
                // Badge chip
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          badge,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Info card at bottom
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                accent.withOpacity(0.9),
                                accent.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Built for quick posts, story moments, and real conversation.',
                            style: AppTheme.whiteTextStyle.copyWith(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}