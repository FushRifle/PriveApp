import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/bloc/settings/settings_bloc.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/providers/theme_provider.dart';
import 'package:clique/ui/pages/settings/subscribe_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Map<String, dynamic>? _user;
  int? _loadedSettingsUserId;

  bool notificationsEnabled = true;
  bool privateAccount = false;
  bool twoFactor = false;

  String selectedLanguage = 'English';
  String selectedQuality = 'HD 1080p';

  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(LoadCurrentUser());

    _loadSettingsIfReady();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          Navigator.pushReplacementNamed(
            context,
            NamedRoutes.loginScreen,
          );
        }
      },
      child: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state.status == UserStatus.success) {
            setState(() {
              _user = state.currentUser;
            });
            _loadSettingsIfReady(forceReload: true);
          }
        },
        builder: (context, state) {
          final user = state.currentUser ?? _user;

          return BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              return Scaffold(
                backgroundColor: isDark
                    ? AppColors.darkBackground
                    : AppColors.settingsLightBackground,
                appBar: AppBar(
                  
                  backgroundColor: AppColors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    'Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: AppColors.text,
                    ),
                  ),
                ),
                body: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      _buildProfileCard(user, isDark),
                      const SizedBox(height: 28),
                      _section(
                        'Appearance',
                        [
                          _themeDropdownTile(
                            isDark: isDark,
                            icon: Icons.dark_mode_rounded,
                            themeMode: themeMode,
                            onChanged: (mode) async {
                              if (mode == null) return;

                              await ref
                                  .read(themeModeProvider.notifier)
                                  .setThemeMode(mode);
                            },
                          ),
                          _divider(isDark),
                          _tile(
                            isDark: isDark,
                            icon: Icons.language_rounded,
                            title: 'Language',
                            subtitle: selectedLanguage,
                            onTap: _showLanguagePicker,
                          ),
                        ],
                        isDark,
                      ),
                      _section(
                        'Privacy',
                        [
                          _switchTile(
                            isDark: isDark,
                            icon: Icons.lock_outline_rounded,
                            title: 'Private Account',
                            subtitle:
                                'Only approved users can see your content',
                            value: privateAccount,
                            onChanged: (v) {
                              setState(() {
                                privateAccount = v;
                              });
                            },
                          ),
                          _divider(isDark),
                          _switchTile(
                            isDark: isDark,
                            icon: Icons.notifications_active_outlined,
                            title: 'Notifications',
                            subtitle: 'Push notifications',
                            value: notificationsEnabled,
                            onChanged: (v) {
                              setState(() {
                                notificationsEnabled = v;
                              });
                            },
                          ),
                        ],
                        isDark,
                      ),
                      _section(
                        'Security',
                        [
                          _switchTile(
                            isDark: isDark,
                            icon: Icons.security_rounded,
                            title: 'Two Factor',
                            subtitle: 'Extra security layer',
                            value: twoFactor,
                            onChanged: (v) {
                              setState(() {
                                twoFactor = v;
                              });

                              if (v) {
                                Navigator.pushNamed(
                                  context,
                                  NamedRoutes.twoFactorScreen,
                                );
                              }
                            },
                          ),
                          _divider(isDark),
                          _tile(
                            isDark: isDark,
                            icon: Icons.password_rounded,
                            title: 'Change Password',
                            subtitle: 'Update password',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                NamedRoutes.changePasswordScreen,
                              );
                            },
                          ),
                          _divider(isDark),
                          _tile(
                            isDark: isDark,
                            icon: Icons.fingerprint_rounded,
                            title: 'App Lock',
                            subtitle: settingsState.getAppLockEnabled
                                ? settingsState.getAppLockTimeoutSeconds > 0
                                    ? 'Enabled • ${_formatLockTimeout(settingsState.getAppLockTimeoutSeconds)} timeout'
                                    : 'Enabled with biometric/PIN'
                                : 'Disabled',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: settingsState.getAppLockEnabled
                                        ? AppColors.primary.withOpacity(0.12)
                                        : AppColors.greyColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    settingsState.getAppLockEnabled
                                        ? 'On'
                                        : 'Off',
                                    style: TextStyle(
                                      color: settingsState.getAppLockEnabled
                                          ? AppColors.primary
                                          : AppColors.greyColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              final settingsBloc = context.read<SettingsBloc>();
                              final userId = _readInt(user?['id']);
                              await Navigator.pushNamed(
                                context,
                                NamedRoutes.lockScreenScreen,
                                arguments: userId > 0 ? userId : null,
                              );
                              if (!mounted) return;
                              settingsBloc.add(
                                LoadSettings(
                                  userId:
                                      userId > 0 ? userId : _currentUserId(),
                                  silent: true,
                                ),
                              );
                            },
                          ),
                        ],
                        isDark,
                      ),
                      _section(
                        'Storage',
                        [
                          _tile(
                            isDark: isDark,
                            icon: Icons.high_quality_rounded,
                            title: 'Video Quality',
                            subtitle: selectedQuality,
                            onTap: _showQualityPicker,
                          ),
                          _divider(isDark),
                          _tile(
                            isDark: isDark,
                            icon: Icons.download_rounded,
                            title: 'Downloads',
                            subtitle: 'Manage downloads',
                            onTap: () {},
                          ),
                        ],
                        isDark,
                      ),
                      _section(
                        'Premium',
                        [
                          _tile(
                            isDark: isDark,
                            icon: Icons.workspace_premium_rounded,
                            title: 'Clique Premium',
                            subtitle: 'Unlock exclusive features',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                ),
                              ),
                              child: const Text(
                                'PREMIUM',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SubscribePage(),
                                ),
                              );
                            },
                          ),
                        ],
                        isDark,
                      ),
                      _section(
                        'About',
                        [
                          _tile(
                            isDark: isDark,
                            icon: Icons.info_outline_rounded,
                            title: 'About Clique',
                            subtitle: 'Version 1.0.0',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                NamedRoutes.aboutScreen,
                              );
                            },
                          ),
                          _divider(isDark),
                          _tile(
                            isDark: isDark,
                            icon: Icons.feedback_outlined,
                            title: 'Feedback',
                            subtitle: 'Report bugs or share ideas',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                NamedRoutes.feedbackScreen,
                              );
                            },
                          ),
                          _divider(isDark),
                          _tile(
                            isDark: isDark,
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            subtitle: 'Read our policies',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                NamedRoutes.termsScreen,
                              );
                            },
                          ),
                          _divider(isDark),
                          _tile(
                            isDark: isDark,
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'Your privacy matters',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                NamedRoutes.privacyScreen,
                              );
                            },
                          ),
                        ],
                        isDark,
                      ),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: _showLogoutDialog,
                        child: Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.redColor.withOpacity(0.08),
                            border: Border.all(
                              color: AppColors.redColor.withOpacity(0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                color: AppColors.redColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _loadSettingsIfReady({bool forceReload = false}) {
    final userId = _currentUserId();
    if (userId == null) return;
    if (!forceReload && _loadedSettingsUserId == userId) return;

    _loadedSettingsUserId = userId;
    context.read<SettingsBloc>().add(LoadSettings(userId: userId));
  }

  String _formatLockTimeout(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    }
    if (seconds % 60 == 0) {
      final minutes = seconds ~/ 60;
      return minutes == 1 ? '1 min' : '$minutes min';
    }

    final minutes = seconds / 60;
    return '${minutes.toStringAsFixed(1)} min';
  }

  Widget _buildProfileCard(Map<String, dynamic>? user, bool isDark) {
    final name = _readUserName(user);
    final avatar = user?['avatar']?.toString() ?? '';
    user?['username']?.toString();
    user?['email']?.toString();

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          NamedRoutes.profileScreen,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.cardBorderColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 25,
              offset: const Offset(0, 8),
              color: AppColors.black.withOpacity(0.04),
            ),
          ],
        ),
        child: Row(
          children: [
            _avatar(
              avatar,
              name,
              isDark,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }

  String _readUserName(Map<String, dynamic>? user) {
    final name = user?['name']?.toString();
    if (name != null && name.trim().isNotEmpty) return name.trim();

    final firstName =
        user?['firstName']?.toString() ?? user?['first_name']?.toString();
    final lastName =
        user?['lastName']?.toString() ?? user?['last_name']?.toString();
    final fullName = [
      firstName,
      lastName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
    if (fullName.trim().isNotEmpty) return fullName.trim();

    final username = user?['username']?.toString();
    if (username != null && username.trim().isNotEmpty) return username.trim();

    final email = user?['email']?.toString();
    if (email != null && email.trim().isNotEmpty) return email.trim();

    return 'User';
  }

  Widget _avatar(
    String avatar,
    String name,
    bool isDark,
  ) {
    final fallback = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatar.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: avatar,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _fallbackAvatar(fallback),
            )
          : _fallbackAvatar(fallback),
    );
  }

  Widget _fallbackAvatar(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
      ),
    );
  }

  Widget _section(
    String title,
    List<Widget> children,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 4,
              bottom: 10,
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.black,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark ? AppColors.darkCard : AppColors.white,
              border: Border.all(
                color: isDark
                    ? AppColors.white10
                    : AppColors.black.withOpacity(0.04),
              ),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 5,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.secondary.withOpacity(0.8),
        ),
        child: Icon(
          icon,
          color: AppColors.white,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.grey,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary,
          ),
    );
  }

  Widget _themeDropdownTile({
    required bool isDark,
    required IconData icon,
    required ThemeMode themeMode,
    required ValueChanged<ThemeMode?> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.secondary.withOpacity(0.8),
        ),
        child: Icon(
          icon,
          color: AppColors.white,
          size: 20,
        ),
      ),
      title: Text(
        'Theme',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.white : AppColors.black,
        ),
      ),
      subtitle: Text(
        'System, light, or dark',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.grey.shade500,
        ),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<ThemeMode>(
          value: themeMode,
          borderRadius: BorderRadius.circular(8),
          dropdownColor: isDark ? AppColors.darkCard : AppColors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.grey.shade500,
          ),
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          items: ThemeMode.values.map((mode) {
            return DropdownMenuItem<ThemeMode>(
              value: mode,
              child: Text(_themeModeLabel(mode)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  Widget _switchTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      secondary: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.secondary.withOpacity(0.8),
        ),
        child: Icon(
          icon,
          color: AppColors.white,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.white : AppColors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.grey.shade500,
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      indent: 78,
      color: AppColors.cardBorder.withOpacity(0.8),
    );
  }

  void _showLanguagePicker() {
    _showPicker(
      title: 'Language',
      values: [
        'English',
        'Spanish',
        'French',
        'German',
      ],
      selected: selectedLanguage,
      onSelected: (v) {
        setState(() {
          selectedLanguage = v;
        });
      },
    );
  }

  void _showQualityPicker() {
    _showPicker(
      title: 'Video Quality',
      values: [
        'Auto',
        '480p',
        '720p',
        'HD 1080p',
        '4K',
      ],
      selected: selectedQuality,
      onSelected: (v) {
        setState(() {
          selectedQuality = v;
        });
      },
    );
  }

  void _showPicker({
    required String title,
    required List<String> values,
    required String selected,
    required Function(String) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(8),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
                const SizedBox(height: 20),
                ...values.map(
                  (e) => ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Text(
                      e,
                      style: TextStyle(
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    trailing: selected == e
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      onSelected(e);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(SignOutRequested());
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: AppColors.redColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _currentUserId() {
    final authUser = context.read<AuthBloc>().state.user;
    final authUserId = _readInt(authUser?['id']);
    if (authUserId > 0) return authUserId;

    final currentUser = context.read<UserBloc>().state.currentUser;
    final currentUserId = _readInt(currentUser?['id']);
    return currentUserId > 0 ? currentUserId : null;
  }
}
