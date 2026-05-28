import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

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
          'Help Center',
          style: TextStyle(
            color: isDarkMode ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(isDarkMode),
            const SizedBox(height: 24),
            _buildFAQSection(context, isDarkMode),
            const SizedBox(height: 24),
            _buildContactSection(context, isDarkMode),
            const SizedBox(height: 24),
            _buildReportSection(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
            color: isDarkMode
                ? AppColors.darkBorderColor
                : AppColors.lightBorderColor.withOpacity(0.5)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for help...',
          hintStyle: AppTheme.greyTextStyle,
          prefixIcon: Icon(Icons.search, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, bool isDarkMode) {
    final faqs = [
      {
        'question': 'How do I create an account?',
        'answer':
            'Tap the "Sign Up" button on the login screen. Enter your email, create a password, and complete your profile information.'
      },
      {
        'question': 'How does matching work?',
        'answer':
            'Our algorithm matches you based on your interests, location, and preferences. You\'ll receive match suggestions in your feed.'
      },
      {
        'question': 'How do I change my profile picture?',
        'answer':
            'Go to your Profile → Edit Profile → Tap on your profile picture → Choose from gallery or take a new photo.'
      },
      {
        'question': 'Can I delete my account?',
        'answer':
            'Yes, go to Settings → Account → Delete Account. This action is permanent and cannot be undone.'
      },
      {
        'question': 'How do I block or report someone?',
        'answer':
            'Go to the user\'s profile → Tap the three dots menu → Select "Block" or "Report".'
      },
      {
        'question': 'Is my data secure?',
        'answer':
            'Yes, we take data security seriously. Your personal information is encrypted and protected. Read our Privacy Policy for more details.'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: faqs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildFAQItem(
              context,
              question: faqs[index]['question']!,
              answer: faqs[index]['answer']!,
              isDarkMode: isDarkMode,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
    required bool isDarkMode,
  }) {
    return ExpansionTile(
      backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
      collapsedBackgroundColor:
          isDarkMode ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: isDarkMode
                ? AppColors.darkBorderColor
                : AppColors.lightBorderColor.withOpacity(0.5)),
      ),
      title: Text(
        question,
        style: AppTheme.blackTextStyle.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: AppTheme.greyTextStyle.copyWith(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Support',
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDarkMode
                    ? AppColors.darkBorderColor
                    : AppColors.lightBorderColor.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              _buildContactTile(
                context,
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'support@clique.com',
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'support@clique.com',
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                },
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildContactTile(
                context,
                icon: Icons.chat_bubble_outline,
                title: 'Live Chat',
                subtitle: 'Available 24/7',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Live chat coming soon!')),
                  );
                },
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report a Problem',
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDarkMode
                    ? AppColors.darkBorderColor
                    : AppColors.lightBorderColor.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              _buildContactTile(
                context,
                icon: Icons.flag_outlined,
                title: 'Report Bug',
                subtitle: 'Tell us about technical issues',
                onTap: () =>
                    _showReportDialog(context, 'Bug Report', isDarkMode),
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildContactTile(
                context,
                icon: Icons.people_outline,
                title: 'Report User',
                subtitle: 'Report inappropriate behavior',
                onTap: () =>
                    _showReportDialog(context, 'User Report', isDarkMode),
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildContactTile(
                context,
                icon: Icons.feedback_outlined,
                title: 'Feature Request',
                subtitle: 'Suggest new features',
                onTap: () =>
                    _showReportDialog(context, 'Feature Request', isDarkMode),
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: AppTheme.blackTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right,
          color: isDarkMode ? AppColors.white54 : AppColors.black54),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      indent: 72,
      color: isDarkMode ? AppColors.darkDivider : AppColors.lightDivider,
    );
  }

  void _showReportDialog(BuildContext context, String type, bool isDarkMode) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          type,
          style: AppTheme.blackTextStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Please describe the issue...',
            hintStyle: AppTheme.greyTextStyle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDarkMode
                      ? AppColors.darkBorderColor
                      : AppColors.lightBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.greyColor)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Thank you for your report! We\'ll review it shortly.'),
                    backgroundColor: AppColors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
