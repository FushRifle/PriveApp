import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';

class ChatSettingsPage extends StatefulWidget {
  final String userName;
  final String userId;

  const ChatSettingsPage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage> {
  bool _isMuted = false;
  bool _isPinned = false;
  String _wallpaper = 'Default';
  String _theme = 'Light';

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
        title: Text(
          'Chat Settings',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chat customization
              _buildSectionTitle('Chat Customization'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildNavigationTile(
                      icon: Icons.wallpaper,
                      title: 'Wallpaper',
                      subtitle: _wallpaper,
                      onTap: () => _showWallpaperPicker(),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildNavigationTile(
                      icon: Icons.palette,
                      title: 'Theme',
                      subtitle: _theme,
                      onTap: () => _showThemePicker(),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildNavigationTile(
                      icon: Icons.text_fields,
                      title: 'Text Size',
                      subtitle: 'Normal',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildNavigationTile(
                      icon: Icons.emoji_emotions,
                      title: 'Emoji',
                      subtitle: 'Default',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notifications
              _buildSectionTitle('Notifications'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications_off,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      title: Text(
                        'Mute Notifications',
                        style: AppTheme.blackTextStyle.copyWith(
                          fontWeight: AppTheme.medium,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        _isMuted ? 'Muted' : 'Unmuted',
                        style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                      ),
                      value: _isMuted,
                      onChanged: (value) {
                        setState(() => _isMuted = value);
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                    if (_isMuted) ...[
                      const Divider(height: 1, indent: 56),
                      _buildNavigationTile(
                        icon: Icons.timer,
                        title: 'Mute Duration',
                        subtitle: '8 hours',
                        onTap: () {},
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Chat actions
              _buildSectionTitle('Chat Actions'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.push_pin,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      title: Text(
                        'Pin Chat',
                        style: AppTheme.blackTextStyle.copyWith(
                          fontWeight: AppTheme.medium,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        _isPinned ? 'Pinned' : 'Not pinned',
                        style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                      ),
                      value: _isPinned,
                      onChanged: (value) {
                        setState(() => _isPinned = value);
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildNavigationTile(
                      icon: Icons.archive,
                      title: 'Archive Chat',
                      subtitle: 'Move chat to archive',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildNavigationTile(
                      icon: Icons.download,
                      title: 'Export Chat',
                      subtitle: 'Download chat history',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildNavigationTile(
                      icon: Icons.search,
                      title: 'Search in Conversation',
                      subtitle: 'Find messages in this chat',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Danger zone
              _buildSectionTitle('Danger Zone'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildNavigationTile(
                      icon: Icons.delete_outline,
                      title: 'Clear Chat',
                      subtitle: 'Delete all messages',
                      titleColor: AppColors.redColor,
                      onTap: () => _showClearChatDialog(),
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildNavigationTile(
                      icon: Icons.block,
                      title:
                          'Block @${widget.userName.toLowerCase().replaceAll(' ', '_')}',
                      subtitle: 'Block this user',
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTheme.blackTextStyle.copyWith(
          fontWeight: AppTheme.bold,
          fontSize: 16,
          color: AppColors.blackTextColor,
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.primary, size: 24),
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
          const Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  void _showWallpaperPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final wallpapers = [
          'Default',
          'Dark',
          'Ocean',
          'Sunset',
          'Forest',
          'Galaxy'
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.greyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Choose Wallpaper',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                    fontSize: 18,
                  )),
              const SizedBox(height: 16),
              ...wallpapers.map((w) => ListTile(
                    title: Text(w,
                        style: AppTheme.blackTextStyle.copyWith(fontSize: 16)),
                    trailing: _wallpaper == w
                        ? const Icon(Icons.check_circle,
                            color: AppColors.purpleColor)
                        : null,
                    onTap: () {
                      setState(() => _wallpaper = w);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final themes = ['Light', 'Dark', 'System'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.greyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Choose Theme',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: AppTheme.bold,
                    fontSize: 18,
                  )),
              const SizedBox(height: 16),
              ...themes.map((t) => ListTile(
                    title: Text(t,
                        style: AppTheme.blackTextStyle.copyWith(fontSize: 16)),
                    trailing: _theme == t
                        ? const Icon(Icons.check_circle,
                            color: AppColors.purpleColor)
                        : null,
                    onTap: () {
                      setState(() => _theme = t);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Clear Chat',
              style:
                  AppTheme.blackTextStyle.copyWith(fontWeight: AppTheme.bold)),
          content: Text(
            'Are you sure you want to delete all messages? This action cannot be undone.',
            style: AppTheme.greyTextStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: AppTheme.blackTextStyle
                      .copyWith(color: AppColors.greyColor)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Clear',
                  style: AppTheme.blackTextStyle.copyWith(
                    color: AppColors.redColor,
                    fontWeight: AppTheme.bold,
                  )),
            ),
          ],
        );
      },
    );
  }
}
