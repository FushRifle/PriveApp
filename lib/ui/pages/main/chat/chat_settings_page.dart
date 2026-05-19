import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cirqle/app/configs/colors.dart';
import 'package:cirqle/app/configs/theme.dart';

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
  String _muteDuration = '8 hours';

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
          'Chat Settings',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: FontWeight.w600,
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
              _buildSettingsCard([
                _buildNavigationTile(
                  icon: Icons.wallpaper,
                  title: 'Wallpaper',
                  subtitle: _wallpaper,
                  onTap: () => _showWallpaperPicker(),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.palette,
                  title: 'Theme',
                  subtitle: _theme,
                  onTap: () => _showThemePicker(),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.text_fields,
                  title: 'Text Size',
                  subtitle: 'Normal',
                  onTap: () => _showTextSizePicker(),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.emoji_emotions,
                  title: 'Emoji',
                  subtitle: 'Default',
                  onTap: () => _showEmojiPicker(),
                ),
              ]),
              const SizedBox(height: 24),

              // Notifications
              _buildSectionTitle('Notifications'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                SwitchListTile(
                  secondary: const Icon(
                    Icons.notifications_off,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  title: Text(
                    'Mute Notifications',
                    style: AppTheme.blackTextStyle.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    _isMuted ? 'Muted for $_muteDuration' : 'Unmuted',
                    style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                  ),
                  value: _isMuted,
                  onChanged: (value) {
                    setState(() => _isMuted = value);
                  },
                  activeThumbColor: AppColors.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                if (_isMuted) ...[
                  _buildDivider(),
                  _buildNavigationTile(
                    icon: Icons.timer,
                    title: 'Mute Duration',
                    subtitle: _muteDuration,
                    onTap: () => _showMuteDurationPicker(),
                  ),
                ],
              ]),
              const SizedBox(height: 24),

              // Chat actions
              _buildSectionTitle('Chat Actions'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                SwitchListTile(
                  secondary: const Icon(
                    Icons.push_pin,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  title: Text(
                    'Pin Chat',
                    style: AppTheme.blackTextStyle.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    _isPinned ? 'Pinned to top' : 'Not pinned',
                    style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                  ),
                  value: _isPinned,
                  onChanged: (value) {
                    setState(() => _isPinned = value);
                  },
                  activeThumbColor: AppColors.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.archive,
                  title: 'Archive Chat',
                  subtitle: 'Move chat to archive',
                  onTap: () => _showArchiveDialog(),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.download,
                  title: 'Export Chat',
                  subtitle: 'Download chat history',
                  onTap: () => _showExportDialog(),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.search,
                  title: 'Search in Conversation',
                  subtitle: 'Find messages in this chat',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Navigate to search
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // Danger zone
              _buildSectionTitle('Danger Zone'),
              const SizedBox(height: 12),
              _buildSettingsCard([
                _buildNavigationTile(
                  icon: Icons.delete_outline,
                  title: 'Clear Chat',
                  subtitle: 'Delete all messages',
                  titleColor: AppColors.redColor,
                  onTap: () => _showClearChatDialog(),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.block,
                  title: 'Block ${widget.userName}',
                  subtitle: 'Block this user',
                  titleColor: AppColors.redColor,
                  onTap: () => _showBlockDialog(),
                ),
              ]),
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
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.greyColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
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
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56);
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
          fontWeight: FontWeight.w500,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose Wallpaper',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...wallpapers.map((w) => ListTile(
                    title: Text(w,
                        style: AppTheme.blackTextStyle.copyWith(fontSize: 16)),
                    trailing: _wallpaper == w
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose Theme',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...themes.map((t) => ListTile(
                    title: Text(t,
                        style: AppTheme.blackTextStyle.copyWith(fontSize: 16)),
                    trailing: _theme == t
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
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

  void _showTextSizePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final sizes = ['Small', 'Normal', 'Large', 'Extra Large'];
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose Text Size',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...sizes.map((s) => ListTile(
                    title: Text(s,
                        style: AppTheme.blackTextStyle.copyWith(fontSize: 16)),
                    trailing:
                        Icon(Icons.chevron_right, color: AppColors.greyColor),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Change text size
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Choose Emoji Style',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('😊', style: TextStyle(fontSize: 24)),
                title: const Text('Default'),
                trailing:
                    const Icon(Icons.check_circle, color: AppColors.primary),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Text('😍', style: TextStyle(fontSize: 24)),
                title: const Text('Cute'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Text('🔥', style: TextStyle(fontSize: 24)),
                title: const Text('Cool'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showMuteDurationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final durations = [
          '1 hour',
          '8 hours',
          '24 hours',
          '7 days',
          'Forever'
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Mute Duration',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...durations.map((d) => ListTile(
                    title: Text(d,
                        style: AppTheme.blackTextStyle.copyWith(fontSize: 16)),
                    trailing: _muteDuration == d
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _muteDuration = d);
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear Chat',
          style: AppTheme.blackTextStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete all messages?\nThis action cannot be undone.',
          style: AppTheme.greyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTheme.greyTextStyle),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Clear chat
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Clear',
              style:
                  AppTheme.blackTextStyle.copyWith(color: AppColors.redColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showArchiveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Archive Chat',
          style: AppTheme.blackTextStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Archive this chat? You can unarchive it later.',
          style: AppTheme.greyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTheme.greyTextStyle),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Archive chat
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat archived'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Archive',
              style: AppTheme.blackTextStyle.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Export Chat',
          style: AppTheme.blackTextStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export chat history as:',
              style: AppTheme.blackTextStyle,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildExportOption('Text', Icons.description),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportOption('PDF', Icons.picture_as_pdf),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportOption('JSON', Icons.code),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTheme.greyTextStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(String format, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        // TODO: Export chat in selected format
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exporting chat as $format...'),
            backgroundColor: AppColors.primary,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              format,
              style: AppTheme.blackTextStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Block ${widget.userName}?',
          style: AppTheme.blackTextStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'They won\'t be able to message you or see your posts.',
          style: AppTheme.greyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTheme.greyTextStyle),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Block user
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User blocked successfully'),
                  backgroundColor: Colors.red,
                ),
              );
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
}
