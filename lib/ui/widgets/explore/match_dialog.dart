import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/models/profile_model.dart';

class MatchDialog extends StatelessWidget {
  final ProfileModel profile;
  final String matchId;
  final VoidCallback onStartChat;
  final VoidCallback onKeepSwiping;

  const MatchDialog({
    super.key,
    required this.profile,
    required this.matchId,
    required this.onStartChat,
    required this.onKeepSwiping,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Celebration animation
              BounceIn(
                duration: const Duration(milliseconds: 800),
                child: Lottie.asset(
                  'assets/animations/match_celebration.json',
                  height: 120,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 20),
              // "It's a match!" text
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    Text(
                      'IT\'S A MATCH!',
                      style: AppTheme.whiteTextStyle.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You and ${profile.name} liked each other',
                      style: AppTheme.whiteTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Profile photos
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProfileCircle(profile.image),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    _buildProfileCircle('assets/avatars/current_user.jpg'),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Action buttons
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: onStartChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Send Message',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: onKeepSwiping,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Keep Swiping',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCircle(String imagePath) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.person,
                size: 50,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
    );
  }
}
