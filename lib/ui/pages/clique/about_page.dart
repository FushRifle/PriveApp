import 'package:clique/core/router/named_routes.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppPageHeader(
            title: 'About Clique',
            subtitle: 'Product, version and useful links',
            leadingIcon: Icons.arrow_back_rounded,
            onLeadingTap: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 32),
              child: Column(
                children: [
                  _buildLogoSection(isDarkMode),
                  const SizedBox(height: 32),
                  _buildInfoCard(isDarkMode),
                  const SizedBox(height: 24),
                  _buildLinksCard(context, isDarkMode),
                  const SizedBox(height: 24),
                  _buildSocialCard(context, isDarkMode),
                  const SizedBox(height: 32),
                  Text(
                    'Fush Inc.',
                    style: AppTheme.greyTextStyle.copyWith(
                        fontSize: 14,
                        color: AppColors.blackTextColor,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              'assets/icons/cliquě-icon.png',
              width: 62,
              height: 62,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Clique',
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Version 1.0.5',
          style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInfoCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode
              ? AppColors.darkBorderColor
              : AppColors.lightBorderColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Clique',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Clique is a modern dating and social networking app that helps you find meaningful connections. Meet new people, share your interests, and build your community.',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Our mission is to create a safe, inclusive platform where genuine connections flourish. Whether you\'re looking for friendship, dating, or professional networking, Clique is your space.',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksCard(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode
              ? AppColors.darkBorderColor
              : AppColors.lightBorderColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Useful Links',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildLinkTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {
              Navigator.pushNamed(context, NamedRoutes.termsScreen);
            },
            isDarkMode: isDarkMode,
          ),
          Divider(
            height: 1,
            color: AppColors.greyTextColor,
          ),
          _buildLinkTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.pushNamed(context, NamedRoutes.privacyScreen);
            },
            isDarkMode: isDarkMode,
          ),
          Divider(
            height: 1,
            color: AppColors.greyTextColor,
          ),
          _buildLinkTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () {
              Navigator.pushNamed(context, NamedRoutes.helpScreen);
            },
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(
        title,
        style: AppTheme.blackTextStyle.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, size: 20, color: AppColors.greyColor),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSocialCard(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode
              ? AppColors.darkBorderColor
              : AppColors.lightBorderColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect With Us',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSocialButton(
                icon: Icons.alternate_email,
                label: 'Email',
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'hello@Clique.com',
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                },
                isDarkMode: isDarkMode,
              ),
              _buildSocialButton(
                icon: Icons.web,
                label: 'Website',
                onTap: () async {
                  final Uri url = Uri.parse('https://Clique.com');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                isDarkMode: isDarkMode,
              ),
              _buildSocialButton(
                icon: Icons.reddit,
                label: 'Reddit',
                onTap: () async {
                  final Uri url = Uri.parse('https://instagram.com/Clique');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                isDarkMode: isDarkMode,
              ),
              _buildSocialButton(
                icon: Icons.facebook,
                label: 'Facebook',
                onTap: () async {
                  final Uri url = Uri.parse('https://facebook.com/Clique');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.greyTextStyle
                .copyWith(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
