import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/router/named_routes.dart';

import 'package:clique/data/models/onboarding_model.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const String _onboardingKey = 'onboarding_completed';

  late final PageController _pageController;

  int _currentPage = 0;

  bool _isNavigating = false;

  final List<OnboardingModel> _onboardingData = [
    OnboardingModel(
      image: 'assets/images/onboarding_1.png',
      title: 'Connect with Friends',
      description:
          'Stay connected with friends and family. Share moments, chat, and make memories together.',
    ),
    OnboardingModel(
      image: 'assets/images/onboarding_2.png',
      title: 'Discover New Content',
      description:
          'Explore trending posts, reels, and stories from creators around the world.',
    ),
    OnboardingModel(
      image: 'assets/images/onboarding_3.png',
      title: 'Express Yourself',
      description:
          'Share your stories, post photos, create reels, and let your creativity shine.',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isNavigating) return;

    _isNavigating = true;

    HapticFeedback.lightImpact();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      _onboardingKey,
      true,
    );

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      NamedRoutes.loginScreen,
    );
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      HapticFeedback.lightImpact();

      _pageController.nextPage(
        duration: const Duration(
          milliseconds: 280,
        ),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSkipButton(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (
                  index,
                ) {
                  if (!mounted) {
                    return;
                  }

                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return RepaintBoundary(
                    child: _OnboardingContent(
                      data: _onboardingData[index],
                      icon: _getIconForPage(
                        index,
                      ),
                    ),
                  );
                },
              ),
            ),
            _BottomSection(
              currentPage: _currentPage,
              totalPages: _onboardingData.length,
              onNext: _nextPage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Padding(
      padding: const EdgeInsets.only(
        right: 24,
        top: 16,
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: TextButton(
          onPressed: _completeOnboarding,
          style: TextButton.styleFrom(
            overlayColor: AppColors.transparent,
          ),
          child: Text(
            'Skip',
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: AppTheme.bold,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForPage(
    int index,
  ) {
    switch (index) {
      case 0:
        return Icons.people_outline;

      case 1:
        return Icons.explore_outlined;

      case 2:
        return Icons.auto_awesome_outlined;

      default:
        return Icons.people_outline;
    }
  }
}

class _OnboardingContent extends StatelessWidget {
  final OnboardingModel data;

  final IconData icon;

  const _OnboardingContent({
    required this.data,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(
                    0.1,
                  ),
                  AppColors.secondary.withOpacity(
                    0.3,
                  ),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 120,
                color: AppColors.blackColor,
              ),
            ),
          ),
          const SizedBox(height: 60),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: AppTheme.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSection extends StatelessWidget {
  final int currentPage;

  final int totalPages;

  final VoidCallback onNext;

  const _BottomSection({
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentPage == totalPages - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => AnimatedContainer(
                duration: const Duration(
                  milliseconds: 250,
                ),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                width: currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: currentPage == index
                      ? AppColors.purpleColor
                      : AppColors.purpleColor.withOpacity(
                          0.3,
                        ),
                  borderRadius: BorderRadius.circular(
                    4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.purpleColor,
                    AppColors.purpleColor.withOpacity(
                      0.8,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  28,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleColor.withOpacity(
                      0.3,
                    ),
                    blurRadius: 20,
                    offset: const Offset(
                      0,
                      10,
                    ),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isLastPage ? 'Get Started' : 'Next',
                  style: AppTheme.whiteTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
