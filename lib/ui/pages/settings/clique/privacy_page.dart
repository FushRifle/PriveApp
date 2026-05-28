import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

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
              color: isDarkMode ? AppColors.white : AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: isDarkMode ? AppColors.white : AppColors.black,
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
              title: '1. Information We Collect',
              content:
                  'We collect information you provide directly to us, including:',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 8),
            _buildSubSection(
              context,
              title: 'Account Information',
              content:
                  '• Name, email address, phone number\n• Profile information (photos, bio, interests)\n• Age, gender, location',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            _buildSubSection(
              context,
              title: 'Usage Information',
              content:
                  '• App activity and interactions\n• Content you view, like, share, or post\n• Search history and preferences',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            _buildSubSection(
              context,
              title: 'Device Information',
              content:
                  '• Device type, operating system, and settings\n• IP address and network information\n• Device identifiers',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '2. How We Use Your Information',
              content: 'We use your information to:',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 8),
            _buildBulletList(
              context,
              items: [
                'Provide, maintain, and improve the App',
                'Match you with other users based on your preferences',
                'Personalize your experience and recommendations',
                'Communicate with you about updates and features',
                'Analyze usage patterns to improve our services',
                'Ensure safety and security of the platform',
              ],
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '3. Information Sharing',
              content:
                  'We may share your information in the following circumstances:',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 8),
            _buildBulletList(
              context,
              items: [
                'With other users (your profile information is visible to matches)',
                'With your consent (you choose to share content)',
                'To comply with legal obligations',
                'To protect the rights and safety of users',
                'With service providers who assist in app operations',
              ],
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '4. Data Security',
              content:
                  'We implement appropriate technical and organizational measures to protect your personal information. However, no method of transmission over the internet is 100% secure.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '5. Your Rights and Choices',
              content: 'You have the right to:',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 8),
            _buildBulletList(
              context,
              items: [
                'Access, update, or delete your personal information',
                'Opt out of marketing communications',
                'Control your privacy settings within the App',
                'Request a copy of your data',
              ],
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '6. Data Retention',
              content:
                  'We retain your information for as long as your account is active or as needed to provide services. You may delete your account at any time, which will remove most of your personal information.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '7. Children\'s Privacy',
              content:
                  'clique is not intended for users under 18. We do not knowingly collect information from minors. If we learn we have collected information from a minor, we will delete it.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '8. International Data Transfers',
              content:
                  'Your information may be transferred to and processed in countries other than your own. We take steps to ensure your data receives adequate protection.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '9. Changes to Privacy Policy',
              content:
                  'We may update this policy from time to time. We will notify you of any material changes through the App or via email.',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '10. Contact Us',
              content:
                  'If you have questions about this Privacy Policy, please contact us:\n• Email: privacy@clique.com\n• In-app: Settings → Help Center',
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
          Text(
            content,
            style: AppTheme.greyTextStyle.copyWith(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSubSection(
    BuildContext context, {
    required String title,
    required String content,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTheme.greyTextStyle.copyWith(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletList(
    BuildContext context, {
    required List<String> items,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: AppTheme.blackTextStyle.copyWith(fontSize: 14)),
                Expanded(
                  child: Text(
                    item,
                    style: AppTheme.greyTextStyle
                        .copyWith(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
