import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/ui/pages/main/chat/chat_settings_page.dart';

class ChatInfoPage extends StatelessWidget {
  final String userName;
  final String userAvatar;
  final String userId;

  const ChatInfoPage({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.userId,
  });

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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chat Info',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatSettingsPage(
                    userName: userName,
                    userId: userId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile section
              _buildProfileSection(),
              const SizedBox(height: 16),

              // Media section
              _buildMediaSection(),
              const SizedBox(height: 16),

              // Shared files
              _buildSharedFilesSection(),
              const SizedBox(height: 16),

              // Privacy & Support
              _buildPrivacySection(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatar(firstLetter),
          const SizedBox(height: 16),
          Text(
            userName,
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${userName.toLowerCase().replaceAll(' ', '_')}',
            style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.greenColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Active now',
                style: AppTheme.greyTextStyle.copyWith(
                  fontSize: 13,
                  color: AppColors.greenColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionChip(
                icon: Icons.call,
                label: 'Audio',
                color: AppColors.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // TODO: Make audio call
                },
              ),
              const SizedBox(width: 16),
              _buildActionChip(
                icon: Icons.videocam,
                label: 'Video',
                color: AppColors.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // TODO: Make video call
                },
              ),
              const SizedBox(width: 16),
              _buildActionChip(
                icon: Icons.person_outline,
                label: 'Profile',
                color: AppColors.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // TODO: View profile
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String fallbackText) {
    final avatar = userAvatar;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary,
          width: 3,
        ),
      ),
      child: ClipOval(
        child: avatar.isNotEmpty
            ? (avatar.startsWith('http')
                ? Image.network(avatar, fit: BoxFit.cover)
                : Image.asset(avatar, fit: BoxFit.cover))
            : Container(
                color: AppColors.primary.withOpacity(0.1),
                child: Center(
                  child: Text(
                    fallbackText,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shared Media',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // TODO: Show all media
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  height: 80,
                  margin: EdgeInsets.only(
                    right: index < 3 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.primary.withOpacity(0.05),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image,
                      color: AppColors.primary.withOpacity(0.3),
                      size: 30,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedFilesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shared Files',
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildFileItem(
            icon: Icons.picture_as_pdf,
            name: 'Project_brief.pdf',
            size: '2.4 MB',
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildFileItem(
            icon: Icons.image,
            name: 'Screenshot_2024.png',
            size: '1.1 MB',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildFileItem(
            icon: Icons.video_file,
            name: 'Tutorial.mp4',
            size: '45.8 MB',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem({
    required IconData icon,
    required String name,
    required String size,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                size,
                style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.download, color: AppColors.primary),
          onPressed: () {
            HapticFeedback.lightImpact();
            // TODO: Download file
          },
        ),
      ],
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    // Add context parameter
    final username = '@${userName.toLowerCase().replaceAll(' ', '_')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.notifications_off_outlined,
            title: 'Mute Notifications',
            subtitle: 'Currently unmuted',
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Mute notifications
            },
          ),
          const Divider(height: 1, indent: 56),
          _buildInfoTile(
            icon: Icons.block_outlined,
            title: 'Block User',
            subtitle: 'Block $username',
            titleColor: AppColors.redColor,
            onTap: () => _showBlockDialog(context), // Pass context
          ),
          const Divider(height: 1, indent: 56),
          _buildInfoTile(
            icon: Icons.report_outlined,
            title: 'Report User',
            subtitle: 'Report inappropriate content',
            titleColor: AppColors.redColor,
            onTap: () => _showReportDialog(context), // Pass context
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.blackColor, size: 24),
      title: Text(
        title,
        style: AppTheme.blackTextStyle.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
      ),
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.greyColor, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Block $userName?', // Use userName directly, not widget.userName
          style: AppTheme.blackTextStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'They won\'t be able to message you or see your posts.',
          style: AppTheme.greyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: AppTheme.greyTextStyle),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // TODO: Block user
            },
            child: Text(
              'Block',
              style:
                  AppTheme.blackTextStyle.copyWith(color: AppColors.redColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Report $userName', // Use userName directly, not widget.userName
          style: AppTheme.blackTextStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'What is the issue?',
              style: AppTheme.blackTextStyle,
            ),
            const SizedBox(height: 16),
            ...['Spam', 'Harassment', 'Inappropriate content', 'Fake account']
                .map((reason) => RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: '',
                      activeColor: AppColors.primary,
                      onChanged: (value) {},
                    )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: AppTheme.greyTextStyle),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // TODO: Report user
            },
            child: Text(
              'Report',
              style:
                  AppTheme.blackTextStyle.copyWith(color: AppColors.redColor),
            ),
          ),
        ],
      ),
    );
  }
}
