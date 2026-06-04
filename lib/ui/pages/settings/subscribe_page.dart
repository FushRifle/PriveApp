import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/subscription/feature_access_cubit.dart';

class SubscribePage extends StatefulWidget {
  const SubscribePage({super.key});

  @override
  State<SubscribePage> createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage> {
  int _selectedPlan = 1; // 0 = Monthly, 1 = Yearly
  List<Package> _packages = const [];
  bool _isLoadingPackages = false;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoadingPackages = true);
    try {
      final packages = await context.read<FeatureAccessCubit>().packages();
      if (!mounted) return;
      setState(() {
        _packages = packages;
        _isLoadingPackages = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPackages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return BlocListener<FeatureAccessCubit, FeatureAccessState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.red,
            ),
          );
        }
        if (state.access.isPremium &&
            !state.isPurchasing &&
            !state.isRestoring) {
          _showPremiumActivated();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'clique Premium',
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
                      colors: [AppColors.purple, AppColors.pink],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    size: 60,
                    color: AppColors.white,
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
                    color: AppColors.white,
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
                                  : AppColors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Monthly',
                                  style: TextStyle(
                                    color: _selectedPlan == 0
                                        ? AppColors.white
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
                                        ? AppColors.white.withOpacity(0.8)
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
                                  : AppColors.transparent,
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
                                            ? AppColors.white
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
                                            ? AppColors.white.withOpacity(0.3)
                                            : AppColors.greenColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Save 50%',
                                        style: TextStyle(
                                          color: _selectedPlan == 1
                                              ? AppColors.white
                                              : AppColors.white,
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
                                        ? AppColors.white.withOpacity(0.8)
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
                  color: AppColors.blue,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  icon: Icons.analytics,
                  title: 'Advanced Analytics',
                  description: 'Detailed insights about your content',
                  color: AppColors.orange,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  icon: Icons.ad_units,
                  title: 'No Ads',
                  description: 'Enjoy an ad-free experience',
                  color: AppColors.green,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  icon: Icons.cloud_upload,
                  title: 'HD Uploads',
                  description: 'Upload high-quality videos and photos',
                  color: AppColors.purple,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  icon: Icons.auto_awesome,
                  title: 'Exclusive Filters',
                  description: 'Access premium filters and effects',
                  color: AppColors.pink,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  icon: Icons.headphones,
                  title: 'Priority Support',
                  description: '24/7 dedicated customer support',
                  color: AppColors.teal,
                ),
                const SizedBox(height: 32),

                // Subscribe button
                BlocBuilder<FeatureAccessCubit, FeatureAccessState>(
                  builder: (context, state) {
                    final isBusy = state.isPurchasing || _isLoadingPackages;
                    return GestureDetector(
                      onTap: isBusy ? null : _purchaseSelectedPlan,
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.purple, AppColors.pink],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isBusy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  state.access.isPremium
                                      ? 'Premium Active'
                                      : 'Subscribe Now',
                                  style: AppTheme.whiteTextStyle.copyWith(
                                    fontWeight: AppTheme.bold,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Cancel anytime. No commitments.',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 32),

                // Restore purchases
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await context.read<FeatureAccessCubit>().restore();
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
        color: AppColors.white,
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

  Future<void> _purchaseSelectedPlan() async {
    HapticFeedback.mediumImpact();

    final cubit = context.read<FeatureAccessCubit>();
    final state = cubit.state;

    if (!state.isRevenueCatConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases are not configured for this build.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    if (_packages.isEmpty) {
      await _loadPackages();
    }

    final selectedPackage = _packageForSelection();
    if (selectedPackage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No subscription package is available right now.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    await cubit.purchase(selectedPackage);
  }

  Package? _packageForSelection() {
    if (_packages.isEmpty) return null;
    final wantsYearly = _selectedPlan == 1;

    for (final package in _packages) {
      final id = package.identifier.toLowerCase();
      if (wantsYearly && (id.contains('annual') || id.contains('year'))) {
        return package;
      }
      if (!wantsYearly && id.contains('month')) {
        return package;
      }
    }

    return _packages.first;
  }

  void _showPremiumActivated() {
    if (!mounted) return;
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
                  'Premium Active',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          content: Text(
            'Your premium access is active and synced on this device.',
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
                    colors: [AppColors.purple, AppColors.pink],
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
