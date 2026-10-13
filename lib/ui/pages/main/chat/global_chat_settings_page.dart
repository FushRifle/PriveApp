import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/core/models/chat_wallpaper.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';

class GlobalChatSettingsPage extends StatefulWidget {
  const GlobalChatSettingsPage({super.key});

  @override
  State<GlobalChatSettingsPage> createState() => _GlobalChatSettingsPageState();
}

class _GlobalChatSettingsPageState extends State<GlobalChatSettingsPage> {
  bool _hydrated = false;
  String _wallpaper = 'default';
  String _chatColor = 'default';
  String _notificationSound = 'default';
  int _fontSize = 16;
  bool _enterToSend = true;
  bool _readReceipts = true;
  bool _typingIndicators = true;
  bool _messagePreview = true;
  String _autoDownloadMedia = 'wifi';

  static const _chatColors = <_ChatColorOption>[
    _ChatColorOption('default', 'Default', AppColors.primary),
    _ChatColorOption('teal', 'Teal', AppColors.secondary),
    _ChatColorOption('blue', 'Blue', AppColors.blue),
    _ChatColorOption('purple', 'Purple', AppColors.purple),
  ];

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadUserPreferences());
  }

  void _hydrate(UserPreferencesModel preferences) {
    setState(() {
      _hydrated = true;
      _wallpaper = preferences.wallpaper;
      _chatColor = preferences.chatColor;
      _notificationSound = preferences.notificationSound;
      _fontSize = preferences.fontSize.clamp(12, 22);
      _enterToSend = preferences.enterToSend;
      _readReceipts = preferences.readReceipts;
      _typingIndicators = preferences.typingIndicators;
      _messagePreview = preferences.messagePreview;
      _autoDownloadMedia = preferences.autoDownloadMedia;
    });
  }

  void _updatePreferences({
    String? wallpaper,
    String? chatColor,
    String? notificationSound,
    int? fontSize,
    bool? enterToSend,
    bool? readReceipts,
    bool? typingIndicators,
    bool? messagePreview,
    String? autoDownloadMedia,
  }) {
    context.read<ChatBloc>().add(
          UpdateUserPreferences(
            wallpaper: wallpaper,
            chatColor: chatColor,
            notificationSound: notificationSound,
            fontSize: fontSize,
            enterToSend: enterToSend,
            readReceipts: readReceipts,
            typingIndicators: typingIndicators,
            messagePreview: messagePreview,
            autoDownloadMedia: autoDownloadMedia,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Chat settings',
            subtitle: 'Defaults for every conversation',
            leadingIcon: Icons.arrow_back_rounded,
            onLeadingTap: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listenWhen: (previous, current) =>
                  previous.userPreferences != current.userPreferences,
              listener: (context, state) {
                final preferences = state.userPreferences;
                if (preferences != null) _hydrate(preferences);
              },
              buildWhen: (previous, current) =>
                  previous.preferencesStatus != current.preferencesStatus ||
                  previous.error != current.error ||
                  previous.userPreferences != current.userPreferences,
              builder: (context, state) {
                if (!_hydrated &&
                    (state.preferencesStatus == ChatStatus.initial ||
                        state.preferencesStatus == ChatStatus.loading)) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (!_hydrated && state.preferencesStatus == ChatStatus.error) {
                  return _SettingsError(
                    message: state.error ?? 'Could not load chat settings',
                    onRetry: () =>
                        context.read<ChatBloc>().add(LoadUserPreferences()),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.secondary,
                  onRefresh: () async {
                    context.read<ChatBloc>().add(LoadUserPreferences());
                    await context.read<ChatBloc>().stream.firstWhere(
                          (state) =>
                              state.preferencesStatus != ChatStatus.loading,
                        );
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 36),
                    children: [
                      _MessagePreview(
                        fontSize: _fontSize.toDouble(),
                        color: _selectedChatColor,
                      ),
                      const SizedBox(height: 12),
                      _SettingsSection(
                        title: 'Appearance',
                        icon: Icons.palette_outlined,
                        children: [
                          _ChatColorSelector(
                            options: _chatColors,
                            selected: _chatColor,
                            onSelected: (value) {
                              HapticFeedback.selectionClick();
                              setState(() => _chatColor = value);
                              _updatePreferences(chatColor: value);
                            },
                          ),
                          const _SettingsDivider(),
                          _SettingsValueTile(
                            icon: Icons.wallpaper_outlined,
                            title: 'Wallpaper',
                            value: ChatWallpapers.byId(_wallpaper).name,
                            onTap: _showWallpaperPicker,
                          ),
                          const _SettingsDivider(),
                          _FontSizeSetting(
                            value: _fontSize.toDouble(),
                            onChanged: (value) {
                              setState(() => _fontSize = value.round());
                            },
                            onChangeEnd: (value) =>
                                _updatePreferences(fontSize: value.round()),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SettingsSection(
                        title: 'Messaging',
                        icon: Icons.chat_bubble_outline_rounded,
                        children: [
                          _SettingsSwitchTile(
                            icon: Icons.keyboard_return_rounded,
                            title: 'Enter to send',
                            subtitle: 'Send messages with the return key',
                            value: _enterToSend,
                            onChanged: (value) {
                              setState(() => _enterToSend = value);
                              _updatePreferences(enterToSend: value);
                            },
                          ),
                          const _SettingsDivider(),
                          _SettingsSwitchTile(
                            icon: Icons.done_all_rounded,
                            title: 'Read receipts',
                            subtitle: 'Let people know when messages are read',
                            value: _readReceipts,
                            onChanged: (value) {
                              setState(() => _readReceipts = value);
                              _updatePreferences(readReceipts: value);
                            },
                          ),
                          const _SettingsDivider(),
                          _SettingsSwitchTile(
                            icon: Icons.more_horiz_rounded,
                            title: 'Typing indicators',
                            subtitle: 'Show when you are typing',
                            value: _typingIndicators,
                            onChanged: (value) {
                              setState(() => _typingIndicators = value);
                              _updatePreferences(typingIndicators: value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SettingsSection(
                        title: 'Notifications',
                        icon: Icons.notifications_none_rounded,
                        children: [
                          _SettingsSwitchTile(
                            icon: Icons.subject_rounded,
                            title: 'Message previews',
                            subtitle: 'Show message text in notifications',
                            value: _messagePreview,
                            onChanged: (value) {
                              setState(() => _messagePreview = value);
                              _updatePreferences(messagePreview: value);
                            },
                          ),
                          const _SettingsDivider(),
                          _SettingsValueTile(
                            icon: Icons.music_note_outlined,
                            title: 'Notification sound',
                            value: _labelize(_notificationSound),
                            onTap: _showSoundPicker,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SettingsSection(
                        title: 'Media',
                        icon: Icons.perm_media_outlined,
                        children: [
                          _SettingsValueTile(
                            icon: Icons.download_outlined,
                            title: 'Auto-download media',
                            value: _downloadLabel(_autoDownloadMedia),
                            onTap: _showDownloadPicker,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color get _selectedChatColor {
    return _chatColors
        .firstWhere(
          (option) => option.id == _chatColor,
          orElse: () => _chatColors.first,
        )
        .color;
  }

  Future<void> _showWallpaperPicker() async {
    final choices = ChatWallpapers.all.take(11).toList();
    final value = await _showChoiceSheet(
      title: 'Default wallpaper',
      values: choices.map((item) => item.id).toList(),
      selected: _wallpaper,
      labelFor: (id) => ChatWallpapers.byId(id).name,
    );
    if (value == null || !mounted) return;
    setState(() => _wallpaper = value);
    _updatePreferences(wallpaper: value);
  }

  Future<void> _showSoundPicker() async {
    final value = await _showChoiceSheet(
      title: 'Notification sound',
      values: const ['default', 'chime', 'pop', 'none'],
      selected: _notificationSound,
      labelFor: _labelize,
    );
    if (value == null || !mounted) return;
    setState(() => _notificationSound = value);
    _updatePreferences(notificationSound: value);
  }

  Future<void> _showDownloadPicker() async {
    final value = await _showChoiceSheet(
      title: 'Auto-download media',
      values: const ['wifi', 'wifi_and_mobile', 'never'],
      selected: _autoDownloadMedia,
      labelFor: _downloadLabel,
    );
    if (value == null || !mounted) return;
    setState(() => _autoDownloadMedia = value);
    _updatePreferences(autoDownloadMedia: value);
  }

  Future<String?> _showChoiceSheet({
    required String title,
    required List<String> values,
    required String selected,
    required String Function(String value) labelFor,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return Material(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 34,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                    child: Text(
                      title,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 15,
                        fontWeight: AppTheme.bold,
                      ),
                    ),
                  ),
                  ...values.map(
                    (value) => ListTile(
                      minTileHeight: 48,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        labelFor(value),
                        style: AppTheme.blackTextStyle.copyWith(
                          fontSize: 12.5,
                          fontWeight: value == selected
                              ? AppTheme.bold
                              : AppTheme.medium,
                        ),
                      ),
                      trailing: value == selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.secondary,
                              size: 20,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, value),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _labelize(String value) {
    if (value == 'none') return 'None';
    if (value.isEmpty) return 'Default';
    return '${value[0].toUpperCase()}${value.substring(1).replaceAll('_', ' ')}';
  }

  String _downloadLabel(String value) {
    return switch (value) {
      'wifi_and_mobile' => 'Wi-Fi and mobile data',
      'never' => 'Never',
      _ => 'Wi-Fi only',
    };
  }
}

class _MessagePreview extends StatelessWidget {
  final double fontSize;
  final Color color;

  const _MessagePreview({required this.fontSize, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: AppTheme.greyTextStyle.copyWith(
              fontSize: 10.5,
              fontWeight: AppTheme.semiBold,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 260),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                'This is how your messages will look.',
                style: AppTheme.whiteTextStyle.copyWith(
                  fontSize: fontSize,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.secondary),
                ),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 13,
                    fontWeight: AppTheme.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.secondary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13),
      secondary: Icon(icon, color: AppColors.textSecondary, size: 19),
      title: Text(
        title,
        style: AppTheme.blackTextStyle.copyWith(
          fontSize: 12.5,
          fontWeight: AppTheme.semiBold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.greyTextStyle.copyWith(fontSize: 10.5, height: 1.3),
      ),
    );
  }
}

class _SettingsValueTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingsValueTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 54,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13),
      leading: Icon(icon, color: AppColors.textSecondary, size: 19),
      title: Text(
        title,
        style: AppTheme.blackTextStyle.copyWith(
          fontSize: 12.5,
          fontWeight: AppTheme.semiBold,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.greyTextStyle.copyWith(fontSize: 10.5),
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
            size: 19,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _FontSizeSetting extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _FontSizeSetting({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.format_size_rounded,
                color: AppColors.textSecondary,
                size: 19,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Message text size',
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 12.5,
                    fontWeight: AppTheme.semiBold,
                  ),
                ),
              ),
              Text(
                '${value.round()} px',
                style: AppTheme.greyTextStyle.copyWith(fontSize: 10.5),
              ),
            ],
          ),
          Slider(
            value: value.clamp(12, 22),
            min: 12,
            max: 22,
            divisions: 5,
            activeColor: AppColors.secondary,
            inactiveColor: AppColors.border,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }
}

class _ChatColorSelector extends StatelessWidget {
  final List<_ChatColorOption> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ChatColorSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 5, 13, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Chat color',
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 12.5,
                fontWeight: AppTheme.semiBold,
              ),
            ),
          ),
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Tooltip(
                message: option.label,
                child: InkWell(
                  onTap: () => onSelected(option.id),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 28,
                    height: 28,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected == option.id
                            ? AppColors.text
                            : AppColors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: option.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Divider(
        height: 1,
        color: AppColors.border.withOpacity(0.42),
      ),
    );
  }
}

class _SettingsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SettingsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.greyTextStyle.copyWith(fontSize: 11.5),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatColorOption {
  final String id;
  final String label;
  final Color color;

  const _ChatColorOption(this.id, this.label, this.color);
}
