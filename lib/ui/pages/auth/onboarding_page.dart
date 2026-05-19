import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cirqle/app/configs/colors.dart';
import 'package:cirqle/app/configs/theme.dart';
import 'package:cirqle/app/resources/constant/named_routes.dart';
import 'package:cirqle/data/models/onboarding_model.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late PageController _pageController;
  int _currentPage = 0;

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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            _buildSkipButton(),
            // Onboarding pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingData[index]);
                },
              ),
            ),
            // Bottom section
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 24, top: 16),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushReplacementNamed(context, NamedRoutes.loginScreen);
          },
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

  Widget _buildOnboardingPage(OnboardingModel data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image placeholder
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.3),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                _getIconForPage(_currentPage),
                size: 120,
                color: AppColors.blackColor,
              ),
            ),
          ),
          const SizedBox(height: 60),
          Text(
            data.title,
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: AppTheme.bold,
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIconForPage(int index) {
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

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Page indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _onboardingData.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.purpleColor
                      : AppColors.purpleColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Next/Get Started button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (_currentPage < _onboardingData.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  NamedRoutes.loginScreen,
                );
              }
            },
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.purpleColor,
                    AppColors.purpleColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purpleColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _currentPage == _onboardingData.length - 1
                      ? 'Get Started'
                      : 'Next',
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
