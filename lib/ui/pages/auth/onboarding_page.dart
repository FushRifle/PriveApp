import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        title: 'Share what actually feels real',
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
        imagePadding: EdgeInsets.only(top: 24),
        titlePadding: EdgeInsets.only(top: 16, bottom: 12),
        bodyPadding: EdgeInsets.symmetric(horizontal: 24),
        pageMargin: EdgeInsets.zero,
      ),
    ),
    PageViewModel(
      titleWidget: const _IntroTitle(
        title: 'Find your people faster',
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
        imagePadding: EdgeInsets.only(top: 24),
        titlePadding: EdgeInsets.only(top: 16, bottom: 12),
        bodyPadding: EdgeInsets.symmetric(horizontal: 24),
        pageMargin: EdgeInsets.zero,
      ),
    ),
    PageViewModel(
      titleWidget: const _IntroTitle(
        title: 'Keep the vibe moving',
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
        imagePadding: EdgeInsets.only(top: 24),
        titlePadding: EdgeInsets.only(top: 16, bottom: 12),
        bodyPadding: EdgeInsets.symmetric(horizontal: 24),
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

    HapticFeedback.lightImpact();

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
        skip: Text(
          'Skip',
          style: AppTheme.whiteTextStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        next: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
        ),
        done: Text(
          'Get started',
          style: AppTheme.whiteTextStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        onDone: _completeOnboarding,
        onSkip: _skipToEnd,
        curve: Curves.easeOutCubic,
        dotsDecorator: DotsDecorator(
          size: const Size.square(7),
          activeSize: const Size(22, 7),
          activeColor: AppColors.primary,
          color: Colors.white.withOpacity(0.18),
          spacing: const EdgeInsets.symmetric(horizontal: 3),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        controlsPadding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
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
    return Text(
      title,
      textAlign: TextAlign.center,
      style: AppTheme.whiteTextStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.1,
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
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppTheme.greyTextStyle.copyWith(
        color: Colors.white.withOpacity(0.72),
        fontSize: 15,
        height: 1.55,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AspectRatio(
        aspectRatio: 0.92,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.26),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.36),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.36),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withOpacity(0.9),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Built for quick posts, story moments, and real conversation.',
                            style: AppTheme.whiteTextStyle.copyWith(
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
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
