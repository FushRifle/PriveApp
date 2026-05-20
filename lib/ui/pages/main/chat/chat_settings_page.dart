import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';

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
  late int _conversationId;
  bool _isMuted = false;
  bool _isPinned = false;
  String _wallpaper = 'default';
  String _chatColor = 'default';
  String _notificationSound = 'default';
  String _muteDuration = '8 hours';
  DateTime? _muteUntil;

  @override
  void initState() {
    super.initState();
    _conversationId = int.tryParse(widget.userId) ?? 0;
    if (_conversationId != 0) {
      _loadSettings();
    }
  }

  void _loadSettings() {
    context
        .read<ChatBloc>()
        .add(LoadChatSettings(conversationId: _conversationId));
  }

  void _updateSettings() {
    DateTime? muteUntil;
    if (_isMuted) {
      switch (_muteDuration) {
        case '1 hour':
          muteUntil = DateTime.now().add(const Duration(hours: 1));
          break;
        case '8 hours':
          muteUntil = DateTime.now().add(const Duration(hours: 8));
          break;
        case '24 hours':
          muteUntil = DateTime.now().add(const Duration(days: 1));
          break;
        case '7 days':
          muteUntil = DateTime.now().add(const Duration(days: 7));
          break;
        case 'Forever':
          muteUntil = null;
          break;
      }
    }

    context.read<ChatBloc>().add(UpdateChatSettings(
          conversationId: _conversationId,
          isPinned: _isPinned,
          isMuted: _isMuted,
          muteUntil: muteUntil,
          wallpaper: _wallpaper,
          chatColor: _chatColor,
          notificationSound: _notificationSound,
        ));
  }

  void _clearChat() {
    context.read<ChatBloc>().add(ClearChat(conversationId: _conversationId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat cleared successfully'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  void _archiveChat() {
    // TODO: Implement archive when endpoint is ready
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat archived'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  void _blockUser() {
    context.read<ChatBloc>().add(BlockUser(userId: _conversationId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User blocked'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pop(context);
  }

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
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state.chatSettings != null) {
            setState(() {
              _isPinned = state.chatSettings!.isPinned;
              _isMuted = state.chatSettings!.isMuted;
              _wallpaper = state.chatSettings!.wallpaper;
              _chatColor = state.chatSettings!.chatColor;
              _notificationSound = state.chatSettings!.notificationSound;
            });
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
            context.read<ChatBloc>().add(ClearChatError());
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
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
                      subtitle: _capitalize(_wallpaper),
                      onTap: () => _showWallpaperPicker(),
                    ),
                    _buildDivider(),
                    _buildNavigationTile(
                      icon: Icons.palette,
                      title: 'Chat Color',
                      subtitle: _capitalize(_chatColor),
                      onTap: () => _showColorPicker(),
                    ),
                    _buildDivider(),
                    _buildNavigationTile(
                      icon: Icons.volume_up,
                      title: 'Notification Sound',
                      subtitle: _capitalize(_notificationSound),
                      onTap: () => _showSoundPicker(),
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
                        _updateSettings();
                      },
                      activeThumbColor: AppColors.primary,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
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
                        _updateSettings();
                      },
                      activeThumbColor: AppColors.primary,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    _buildDivider(),
                    _buildNavigationTile(
                      icon: Icons.archive,
                      title: 'Archive Chat',
                      subtitle: 'Move chat to archive',
                      onTap: _showArchiveDialog,
                    ),
                    _buildDivider(),
                    _buildNavigationTile(
                      icon: Icons.search,
                      title: 'Search in Conversation',
                      subtitle: 'Find messages in this chat',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // TODO: Navigate to search in chat
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
                      onTap: _showClearChatDialog,
                    ),
                    _buildDivider(),
                    _buildNavigationTile(
                      icon: Icons.block,
                      title: 'Block ${widget.userName}',
                      subtitle: 'Block this user',
                      titleColor: AppColors.redColor,
                      onTap: _showBlockDialog,
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
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
    final wallpapers = [
      'default',
      'dark',
      'ocean',
      'sunset',
      'forest',
      'galaxy'
    ];
    _showPicker(
      title: 'Choose Wallpaper',
      items: wallpapers,
      selectedValue: _wallpaper,
      onSelected: (value) {
        setState(() => _wallpaper = value);
        _updateSettings();
      },
    );
  }

  void _showColorPicker() {
    final colors = [
      'default',
      'primary',
      'blue',
      'green',
      'purple',
      'pink',
      'orange'
    ];
    _showPicker(
      title: 'Choose Chat Color',
      items: colors,
      selectedValue: _chatColor,
      onSelected: (value) {
        setState(() => _chatColor = value);
        _updateSettings();
      },
    );
  }

  void _showSoundPicker() {
    final sounds = ['default', 'classic', 'gentle', 'pop', 'ping'];
    _showPicker(
      title: 'Choose Notification Sound',
      items: sounds,
      selectedValue: _notificationSound,
      onSelected: (value) {
        setState(() => _notificationSound = value);
        _updateSettings();
      },
    );
  }

  void _showMuteDurationPicker() {
    final durations = ['1 hour', '8 hours', '24 hours', '7 days', 'Forever'];
    _showPicker(
      title: 'Mute Duration',
      items: durations,
      selectedValue: _muteDuration,
      onSelected: (value) {
        setState(() => _muteDuration = value);
        _updateSettings();
      },
    );
  }

  void _showPicker({
    required String title,
    required List<String> items,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
                title,
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => ListTile(
                  title: Text(
                    _capitalize(item),
                    style: AppTheme.blackTextStyle.copyWith(fontSize: 16),
                  ),
                  trailing: selectedValue == item
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(item);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
              _clearChat();
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
              _archiveChat();
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
              _blockUser();
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
