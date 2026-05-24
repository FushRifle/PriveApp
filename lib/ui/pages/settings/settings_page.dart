import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/app/resources/constant/named_routes.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/bloc/profile/gallery_profile_cubit.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/data/providers/theme_provider.dart';
import 'package:clique/ui/pages/main/profile/profile_page.dart';
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
  Profile? _profile;

  bool notificationsEnabled = true;
  bool privateAccount = false;
  bool twoFactor = false;

  String selectedLanguage = 'English';
  String selectedQuality = 'HD 1080p';

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadMyProfile());
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
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
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.success) {
            setState(() {
              _profile = state.myProfile;
            });
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            );
          }

          if (state.status == ProfileStatus.error) {
            return Scaffold(
              backgroundColor:
                  isDark ? AppColors.darkBackground : AppColors.lightBackground,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 70,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        state.error ?? 'Something went wrong',
                        textAlign: TextAlign.center,
                        style: AppTheme.greyTextStyle,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ProfileBloc>().add(LoadMyProfile());
                        },
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor:
                isDark ? AppColors.darkBackground : const Color(0xfff7f7f7),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
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
                  _buildProfileCard(isDark),
                  const SizedBox(height: 28),
                  _section(
                    'Appearance',
                    [
                      _switchTile(
                        isDark: isDark,
                        icon: Icons.dark_mode_rounded,
                        title: 'Dark Mode',
                        subtitle: 'Switch app appearance',
                        value: isDark,
                        onChanged: (_) async {
                          await ref
                              .read(themeModeProvider.notifier)
                              .toggleTheme();
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
                                Colors.purple,
                                Colors.pink,
                              ],
                            ),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
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

  Widget _buildProfileCard(bool isDark) {
    final name =
        _profile?.displayName ?? _profile?.displayNameOrDefault ?? 'User';

    final avatar = _profile?.avatar ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(
                  value: context.read<ProfileBloc>(),
                ),
                BlocProvider(
                  create: (_) => GalleryProfileCubit(),
                ),
              ],
              child: const ProfilePage(
                isOwnProfile: true,
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: isDark ? AppColors.darkCard : Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 25,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.04),
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
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View profile',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
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
          color: Colors.white,
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
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
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
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade500,
          ),
    );
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
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      indent: 78,
      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
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
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
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
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
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
                        color: isDark ? Colors.white : Colors.black,
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
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
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
                color: Colors.grey.shade600,
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
