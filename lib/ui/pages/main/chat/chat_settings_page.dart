import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/core/services/chat/chat_service.dart';

class ChatSettingsPage extends StatefulWidget {
  final String userName;
  final int conversationId;
  final int userId;

  const ChatSettingsPage({
    super.key,
    required this.userName,
    required this.conversationId,
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
  final ChatService _chatService = ChatService();

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface => AppColors.getCardColor(_isDark);
  Color get _border => AppColors.getCardBorderColor(_isDark);
  Color get _text => AppColors.getTextColor(_isDark);
  Color get _mutedText => AppColors.getTextSecondaryColor(_isDark);
  Color get _divider => AppColors.getDividerColor(_isDark);

  // Wallpaper assets
  final List<WallpaperItem> _wallpapers = [
    WallpaperItem(id: 'default', name: 'Default', asset: null, color: null),
    WallpaperItem(
        id: 'palms',
        name: 'Palms',
        asset: 'assets/wallpapers/palms.png',
        color: null),
    WallpaperItem(
        id: 'modern',
        name: 'Modern',
        asset: 'assets/wallpapers/modern.png',
        color: null),
    WallpaperItem(
        id: 'sunset',
        name: 'Sunset',
        asset: 'assets/wallpapers/sunset.png',
        color: null),
    WallpaperItem(
        id: 'sky',
        name: 'Sky',
        asset: 'assets/wallpapers/sky.png',
        color: null),
    WallpaperItem(
        id: 'galaxy',
        name: 'Galaxy',
        asset: 'assets/wallpapers/galaxy.png',
        color: null),
  ];

  // Color options
  final List<ColorOption> _colorOptions = [
    ColorOption(id: 'default', name: 'Default', color: AppColors.primary),
    ColorOption(id: 'blue', name: 'Blue', color: AppColors.blue),
    ColorOption(id: 'green', name: 'Green', color: AppColors.green),
    ColorOption(id: 'purple', name: 'Purple', color: AppColors.purple),
    ColorOption(id: 'pink', name: 'Pink', color: AppColors.pink),
    ColorOption(id: 'orange', name: 'Orange', color: AppColors.orange),
    ColorOption(id: 'teal', name: 'Teal', color: AppColors.teal),
    ColorOption(id: 'indigo', name: 'Indigo', color: AppColors.indigo),
  ];

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    if (_conversationId != 0) {
      _loadSettings();
    }
  }

  void _loadSettings() {
    context
        .read<ChatBloc>()
        .add(LoadChatSettings(conversationId: _conversationId));
  }

  void _updateSettings({bool showSnackbar = false}) {
    DateTime? muteUntil;
    if (_isMuted && _muteDuration != 'Forever') {
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
      }
    }

    context.read<ChatBloc>().add(UpdateChatSettings(
          conversationId: _conversationId,
          isPinned: _isPinned,
          isMuted: _isMuted,
          muteUntil: _isMuted && _muteDuration != 'Forever' ? muteUntil : null,
          wallpaper: _wallpaper,
          chatColor: _chatColor,
          notificationSound: _notificationSound,
        ));

    if (showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Settings updated'),
            backgroundColor: AppColors.card,
            duration: const Duration(seconds: 1)),
      );
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Chat'),
        content: const Text('Delete all messages? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<ChatBloc>()
                  .add(ClearChat(conversationId: _conversationId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Chat cleared',
                    style: TextStyle(color: AppColors.text),
                  ),
                  backgroundColor: AppColors.card,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Block ${widget.userName}?'),
        content:
            const Text('They won\'t be able to message you or see your posts.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(BlockUser(userId: widget.userId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'User blocked',
                    style: TextStyle(color: AppColors.text),
                  ),
                  backgroundColor: AppColors.card,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Block', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  bool get _isBot => widget.userName.toLowerCase() == 'Clique';

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: _isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chat Settings',
          style: AppTheme.blackTextStyle
              .copyWith(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listenWhen: (previous, current) =>
            previous.chatSettings != current.chatSettings,
        listener: (context, state) {
          final settings = state.chatSettings;
          if (settings != null &&
              (_isPinned != settings.isPinned ||
                  _isMuted != settings.isMuted ||
                  _wallpaper != settings.wallpaper ||
                  _chatColor != settings.chatColor ||
                  _notificationSound != settings.notificationSound)) {
            setState(() {
              _isPinned = settings.isPinned;
              _isMuted = settings.isMuted;
              _wallpaper = settings.wallpaper;
              _chatColor = settings.chatColor;
              _notificationSound = settings.notificationSound;
            });
          }
        },
        buildWhen: (previous, current) =>
            previous.settingsStatus != current.settingsStatus ||
            previous.chatSettings != current.chatSettings,
        builder: (context, state) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Chat Customization'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildWallpaperTile(),
                    _buildDivider(),
                    _buildColorTile(),
                    if (!_isBot) ...[
                      _buildDivider(),
                      _buildSoundTile(),
                    ],
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Notifications'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildMuteSwitch(),
                    if (_isMuted) ...[
                      _buildDivider(),
                      _buildMuteDurationTile(),
                    ],
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Chat Actions'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildPinSwitch(),
                    _buildDivider(),
                    _buildArchiveTile(),
                    _buildDivider(),
                    _buildSearchTile(),
                  ]),
                  if (!_isBot) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Danger Zone'),
                    const SizedBox(height: 12),
                    _buildSettingsCard([
                      _buildClearChatTile(),
                      _buildDivider(),
                      _buildBlockTile(),
                    ]),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWallpaperTile() {
    final currentWallpaper = _wallpapers.firstWhere((w) => w.id == _wallpaper,
        orElse: () => _wallpapers.first);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primary.withOpacity(0.08),
          border: Border.all(color: _border),
          image: currentWallpaper.asset != null
              ? DecorationImage(
                  image: AssetImage(currentWallpaper.asset!), fit: BoxFit.cover)
              : null,
        ),
        child: currentWallpaper.asset == null
            ? const Icon(Icons.wallpaper, color: AppColors.primary, size: 20)
            : null,
      ),
      title: Text('Wallpaper',
          style: AppTheme.blackTextStyle
              .copyWith(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(_capitalize(_wallpaper),
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: _mutedText, size: 20),
      onTap: () => _showWallpaperPicker(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildColorTile() {
    final currentColor = _colorOptions.firstWhere((c) => c.id == _chatColor,
        orElse: () => _colorOptions.first);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: currentColor.color,
          border: Border.all(color: _border, width: 2),
        ),
        child: _chatColor == 'default'
            ? const Icon(Icons.palette, color: AppColors.white, size: 20)
            : null,
      ),
      title: Text('Chat Color',
          style: AppTheme.blackTextStyle
              .copyWith(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(_capitalize(_chatColor),
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: _mutedText, size: 20),
      onTap: () => _showColorPicker(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildSoundTile() {
    return ListTile(
      leading: const Icon(Icons.volume_up, color: AppColors.primary, size: 24),
      title: Text('Notification Sound',
          style: AppTheme.blackTextStyle
              .copyWith(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(_capitalize(_notificationSound),
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: _mutedText, size: 20),
      onTap: () => _showSoundPicker(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildMuteSwitch() {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_off,
          color: AppColors.primary, size: 24),
      title: Text('Mute Notifications',
          style: AppTheme.blackTextStyle
              .copyWith(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(_isMuted ? 'Muted for $_muteDuration' : 'Unmuted',
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      value: _isMuted,
      onChanged: (value) {
        setState(() => _isMuted = value);
        _updateSettings();
      },
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildMuteDurationTile() {
    return ListTile(
      leading: const Icon(Icons.timer, color: AppColors.primary, size: 24),
      title: Text('Mute Duration',
          style: AppTheme.blackTextStyle
              .copyWith(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(_muteDuration,
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: _mutedText, size: 20),
      onTap: () => _showMuteDurationPicker(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildPinSwitch() {
    return SwitchListTile(
      secondary: const Icon(Icons.push_pin, color: AppColors.primary, size: 24),
      title: Text('Pin Chat',
          style: AppTheme.blackTextStyle
              .copyWith(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(_isPinned ? 'Pinned to top' : 'Not pinned',
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      value: _isPinned,
      onChanged: (value) {
        setState(() => _isPinned = value);
        _updateSettings();
      },
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildArchiveTile() {
    return ListTile(
      leading: const Icon(Icons.archive, color: AppColors.primary, size: 24),
      title: Text('Archive Chat',
          style: AppTheme.blackTextStyle
              .copyWith(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text('Move chat to archive',
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: _mutedText, size: 20),
      onTap: () async {
        await _chatService.archiveConversation(widget.conversationId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chat archived',
              style: TextStyle(color: AppColors.text),
            ),
            backgroundColor: AppColors.card,
          ),
        );
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildSearchTile() {
    return ListTile(
      leading: const Icon(Icons.search, color: AppColors.primary, size: 24),
      title: Text('Search in Conversation',
          style: AppTheme.blackTextStyle
              .copyWith(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text('Find messages in this chat',
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: _mutedText, size: 20),
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Implement search
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildClearChatTile() {
    return ListTile(
      leading: const Icon(Icons.delete_outline, color: AppColors.red, size: 24),
      title: Text('Clear Chat',
          style: AppTheme.blackTextStyle.copyWith(
              fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.red)),
      subtitle: Text('Delete all messages',
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      onTap: _clearChat,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildBlockTile() {
    return ListTile(
      leading: const Icon(Icons.block, color: AppColors.red, size: 24),
      title: Text('Block ${widget.userName}',
          style: AppTheme.blackTextStyle.copyWith(
              fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.red)),
      subtitle: Text('Block this user',
          style: AppTheme.greyTextStyle.copyWith(fontSize: 12)),
      onTap: _blockUser,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
          color: _mutedText,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: AppColors.getShadowColor(_isDark),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() => Divider(height: 1, indent: 56, color: _divider);

  void _showWallpaperPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.greyColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2))),
              Text('Choose Wallpaper',
                  style: AppTheme.blackTextStyle
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _wallpapers.length,
                  itemBuilder: (context, index) {
                    final wallpaper = _wallpapers[index];
                    final isSelected = _wallpaper == wallpaper.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _wallpaper = wallpaper.id);
                        _updateSettings(showSnackbar: true);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.transparent,
                              width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: wallpaper.asset != null
                              ? Stack(
                                  children: [
                                    Image.asset(wallpaper.asset!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity),
                                    if (isSelected)
                                      Container(
                                        decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.3)),
                                        child: const Center(
                                            child: Icon(Icons.check_circle,
                                                color: AppColors.white,
                                                size: 32)),
                                      ),
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: AppColors.black
                                                .withOpacity(0.6),
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Text(wallpaper.name,
                                            style: const TextStyle(
                                                color: AppColors.white,
                                                fontSize: 10)),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  color: AppColors.primary.withOpacity(0.08),
                                  child: Stack(
                                    children: [
                                      const Center(
                                          child: Icon(Icons.wallpaper,
                                              size: 40,
                                              color: AppColors.primary)),
                                      if (isSelected)
                                        Container(
                                          decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withOpacity(0.3)),
                                          child: const Center(
                                              child: Icon(Icons.check_circle,
                                                  color: AppColors.white,
                                                  size: 32)),
                                        ),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: AppColors.black
                                                  .withOpacity(0.6),
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Text(wallpaper.name,
                                              style: const TextStyle(
                                                  color: AppColors.white,
                                                  fontSize: 10)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.greyColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            Text('Choose Chat Color',
                style: AppTheme.blackTextStyle
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _colorOptions
                  .map((color) => GestureDetector(
                        onTap: () {
                          setState(() => _chatColor = color.id);
                          _updateSettings(showSnackbar: true);
                          Navigator.pop(context);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.color,
                                border: Border.all(
                                    color: _chatColor == color.id
                                        ? AppColors.primary
                                        : AppColors.transparent,
                                    width: 3),
                              ),
                              child: _chatColor == color.id
                                  ? const Center(
                                      child: Icon(Icons.check,
                                          color: AppColors.white, size: 30))
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(color.name,
                                style: AppTheme.greyTextStyle
                                    .copyWith(fontSize: 12)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSoundPicker() {
    final sounds = ['default', 'classic', 'gentle', 'pop', 'ping'];
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                    color: AppColors.greyColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Choose Notification Sound',
                style: AppTheme.blackTextStyle
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ...sounds.map((sound) => ListTile(
                  title: Text(_capitalize(sound),
                      style: AppTheme.blackTextStyle.copyWith(fontSize: 16)),
                  trailing: _notificationSound == sound
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _notificationSound = sound);
                    _updateSettings(showSnackbar: true);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMuteDurationPicker() {
    final durations = ['1 hour', '8 hours', '24 hours', '7 days', 'Forever'];
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                    color: AppColors.greyColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Mute Duration',
                style: AppTheme.blackTextStyle
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ...durations.map((duration) => ListTile(
                  title: Text(duration,
                      style: AppTheme.blackTextStyle.copyWith(fontSize: 16)),
                  trailing: _muteDuration == duration
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _muteDuration = duration);
                    _updateSettings();
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class WallpaperItem {
  final String id;
  final String name;
  final String? asset;
  final Color? color;

  WallpaperItem({required this.id, required this.name, this.asset, this.color});
}

class ColorOption {
  final String id;
  final String name;
  final Color color;

  ColorOption({required this.id, required this.name, required this.color});
}
