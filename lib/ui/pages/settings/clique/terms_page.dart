import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms of Service',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: '1. Acceptance of Terms',
              content:
                  'By downloading, accessing, or using clique ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '2. Eligibility',
              content:
                  'You must be at least 18 years old to use clique. By using the App, you represent and warrant that you meet this age requirement and have the full authority to enter into these terms.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '3. Account Registration',
              content:
                  'To use certain features, you must create an account. You agree to provide accurate, current, and complete information and to update it as necessary. You are responsible for maintaining the confidentiality of your login credentials.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '4. User Conduct',
              content:
                  'You agree not to:\n• Harass, abuse, or harm other users\n• Post inappropriate, offensive, or illegal content\n• Impersonate any person or entity\n• Use the App for any unlawful purpose\n• Attempt to gain unauthorized access to the App or its systems',
              isDarkMode: isDarkMode,
              isBulletList: true,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '5. Content Ownership',
              content:
                  'You retain ownership of any content you post. By posting content, you grant clique a worldwide, non-exclusive, royalty-free license to use, display, and distribute your content within the App.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '6. Privacy',
              content:
                  'Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your personal information.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '7. Termination',
              content:
                  'We reserve the right to suspend or terminate your account at our sole discretion, without notice, for conduct that violates these terms or is harmful to other users.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '8. Disclaimer of Warranties',
              content:
                  'The App is provided "as is" without warranties of any kind. We do not guarantee that the App will be uninterrupted or error-free.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '9. Limitation of Liability',
              content:
                  'To the maximum extent permitted by law, clique shall not be liable for any indirect, incidental, or consequential damages arising from your use of the App.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '10. Changes to Terms',
              content:
                  'We may modify these terms at any time. Continued use of the App after changes constitutes acceptance of the new terms.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '11. Contact Us',
              content:
                  'If you have any questions about these Terms, please contact us at: support@clique.com',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last Updated: May 2025',
                style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    required bool isDarkMode,
    bool isBulletList = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDarkMode
                ? AppColors.darkBorderColor
                : AppColors.lightBorderColor.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (isBulletList)
            ...content
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .map((line) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style: AppTheme.blackTextStyle.copyWith(fontSize: 14)),
                    Expanded(
                      child: Text(
                        line.trim(),
                        style: AppTheme.greyTextStyle
                            .copyWith(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }).toList()
          else
            Text(
              content,
              style: AppTheme.greyTextStyle.copyWith(fontSize: 14, height: 1.5),
            ),
        ],
      ),
    );
  }
}
