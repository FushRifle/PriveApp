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
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.purpleColor,
                          width: 3,
                        ),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: AssetImage(userAvatar),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontWeight: AppTheme.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${userName.toLowerCase().replaceAll(' ', '_')}',
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionChip(
                          icon: Icons.call,
                          label: 'Audio',
                          color: AppColors.greenColor,
                          onTap: () {},
                        ),
                        const SizedBox(width: 16),
                        _buildActionChip(
                          icon: Icons.videocam,
                          label: 'Video',
                          color: AppColors.purpleColor,
                          onTap: () {},
                        ),
                        const SizedBox(width: 16),
                        _buildActionChip(
                          icon: Icons.person_add,
                          label: 'Profile',
                          color: Colors.blue,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Media section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                            fontWeight: AppTheme.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'See all',
                          style: AppTheme.blackTextStyle.copyWith(
                            color: AppColors.purpleColor,
                            fontSize: 14,
                          ),
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
                              color: AppColors.purpleColor.withOpacity(0.1),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image,
                                color: AppColors.purpleColor.withOpacity(0.5),
                                size: 30,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Shared files
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shared Files',
                      style: AppTheme.blackTextStyle.copyWith(
                        fontWeight: AppTheme.bold,
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
              ),
              const SizedBox(height: 16),

              // Privacy & Support
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.notifications_off_outlined,
                      title: 'Mute Notifications',
                      subtitle: 'Currently unmuted',
                      onTap: () {},
                    ),
                    const Divider(),
                    _buildInfoTile(
                      icon: Icons.block_outlined,
                      title: 'Block User',
                      subtitle:
                          'Block @${userName.toLowerCase().replaceAll(' ', '_')}',
                      titleColor: AppColors.redColor,
                      onTap: () {},
                    ),
                    const Divider(),
                    _buildInfoTile(
                      icon: Icons.report_outlined,
                      title: 'Report User',
                      subtitle: 'Report inappropriate content',
                      titleColor: AppColors.redColor,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 12,
              fontWeight: AppTheme.medium,
            ),
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
          width: 44,
          height: 44,
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
                  fontWeight: AppTheme.medium,
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
        const Icon(Icons.download, color: AppColors.purpleColor, size: 22),
      ],
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
          fontWeight: AppTheme.medium,
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
}
