import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';

class SubscribePage extends StatefulWidget {
  const SubscribePage({super.key});

  @override
  State<SubscribePage> createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage> {
  int _selectedPlan = 1; // 0 = Monthly, 1 = Yearly

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Prive Premium',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Crown icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.pink],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Upgrade to Premium',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: AppTheme.bold,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Unlock all features and take your experience to the next level',
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Plan toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPlan = 0;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedPlan == 0
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Monthly',
                                style: TextStyle(
                                  color: _selectedPlan == 0
                                      ? Colors.white
                                      : AppColors.blackColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$9.99/mo',
                                style: TextStyle(
                                  color: _selectedPlan == 0
                                      ? Colors.white.withOpacity(0.8)
                                      : AppColors.greyColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPlan = 1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedPlan == 1
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Yearly',
                                    style: TextStyle(
                                      color: _selectedPlan == 1
                                          ? Colors.white
                                          : AppColors.blackColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedPlan == 1
                                          ? Colors.white.withOpacity(0.3)
                                          : AppColors.greenColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Save 50%',
                                      style: TextStyle(
                                        color: _selectedPlan == 1
                                            ? Colors.white
                                            : Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$4.99/mo',
                                style: TextStyle(
                                  color: _selectedPlan == 1
                                      ? Colors.white.withOpacity(0.8)
                                      : AppColors.greyColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Features list
              _buildFeatureItem(
                icon: Icons.verified,
                title: 'Verified Badge',
                description: 'Get a blue checkmark and stand out',
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                icon: Icons.analytics,
                title: 'Advanced Analytics',
                description: 'Detailed insights about your content',
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                icon: Icons.ad_units,
                title: 'No Ads',
                description: 'Enjoy an ad-free experience',
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                icon: Icons.cloud_upload,
                title: 'HD Uploads',
                description: 'Upload high-quality videos and photos',
                color: Colors.purple,
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                icon: Icons.auto_awesome,
                title: 'Exclusive Filters',
                description: 'Access premium filters and effects',
                color: Colors.pink,
              ),
              const SizedBox(height: 20),
              _buildFeatureItem(
                icon: Icons.headphones,
                title: 'Priority Support',
                description: '24/7 dedicated customer support',
                color: Colors.teal,
              ),
              const SizedBox(height: 32),

              // Subscribe button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showSubscribeConfirmation();
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.pink],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Subscribe Now',
                      style: AppTheme.whiteTextStyle.copyWith(
                        fontWeight: AppTheme.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cancel anytime. No commitments.',
                style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 32),

              // Restore purchases
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // TODO: Restore purchases
                },
                child: Text(
                  'Restore Purchases',
                  style: AppTheme.blackTextStyle.copyWith(
                    color: AppColors.primary,
                    fontWeight: AppTheme.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Terms
              Text(
                'By subscribing you agree to our Terms of Service and Privacy Policy',
                style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscribeConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.greenColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.greenColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to Premium!',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          content: Text(
            'You now have access to all premium features. Enjoy your enhanced experience!',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.pink],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    'Continue',
                    style: AppTheme.whiteTextStyle.copyWith(
                      fontWeight: AppTheme.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
