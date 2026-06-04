import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/providers/theme_provider.dart';
import 'package:clique/ui/pages/settings/subscribe_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Map<String, dynamic>? _user;

  bool notificationsEnabled = true;
  bool privateAccount = false;
  bool twoFactor = false;

  String selectedLanguage = 'English';
  String selectedQuality = 'HD 1080p';

  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(LoadCurrentUser());
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
          }
        },
        builder: (context, state) {
          final user = state.currentUser ?? _user;

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
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
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
                        subtitle: 'Only approved users can see your content',
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
                        title: 'Two Factor Authentication',
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
                        subtitle: 'Biometric & PIN',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            NamedRoutes.lockScreenScreen,
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
                                AppColors.purple,
                                AppColors.pink,
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
                        borderRadius: BorderRadius.circular(18),
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
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic>? user, bool isDark) {
    final name = _readUserName(user);
    final avatar = user?['avatar']?.toString() ?? '';
    final username = user?['username']?.toString();
    final email = user?['email']?.toString();
    final subtitle = username != null && username.trim().isNotEmpty
        ? '@${username.trim()}'
        : email != null && email.trim().isNotEmpty
            ? email.trim()
            : 'View profile';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          NamedRoutes.profileScreen,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: isDark ? AppColors.darkCard : AppColors.white,
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
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.grey.shade500,
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
      width: 68,
      height: 68,
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
          ? Image.network(
              avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackAvatar(fallback),
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
      padding: const EdgeInsets.only(bottom: 26),
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
              borderRadius: BorderRadius.circular(24),
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
        horizontal: 18,
        vertical: 4,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.primary.withOpacity(0.1),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
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
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.grey.shade500,
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
        horizontal: 18,
        vertical: 4,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.primary.withOpacity(0.1),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
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
          borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(14),
          color: AppColors.primary.withOpacity(0.1),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
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
      color: isDark ? AppColors.white10 : AppColors.black.withOpacity(0.05),
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
          top: Radius.circular(28),
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
                    borderRadius: BorderRadius.circular(20),
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
                      borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(24),
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
}
