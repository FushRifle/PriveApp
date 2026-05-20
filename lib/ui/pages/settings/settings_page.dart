import 'package:clique/bloc/profile/gallery_profile_cubit.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/ui/pages/main/profile/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/app/resources/constant/named_routes.dart';
import 'package:clique/ui/pages/settings/subscribe_page.dart';
import 'package:clique/data/providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isLoading = true;
  String? _error;
  Profile? _profile;

  bool _isNotificationsEnabled = true;
  bool _isPrivateAccount = false;
  bool _isTwoFactorAuth = false;
  String _selectedLanguage = 'English';
  String _selectedVideoQuality = 'HD 1080p';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<ProfileBloc>().add(LoadMyProfile());
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.success) {
            setState(() {
              _profile = state.myProfile;
              _isLoading = false;
              _error = null;
            });
          } else if (state.status == ProfileStatus.error) {
            setState(() {
              _error = state.error;
              _isLoading = false;
            });
          }
        },
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.unauthenticated) {
              Navigator.pushReplacementNamed(context, NamedRoutes.loginScreen);
            }
          },
          child: _buildBody(isDarkMode),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTheme.greyTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final userName =
        _profile?.displayName ?? _profile?.displayNameOrDefault ?? 'User';
    final userAvatar = _profile?.avatar ?? '';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            _buildProfileSection(userName, userAvatar, isDarkMode),
            const SizedBox(height: 24),

            // Appearance
            _buildSectionTitle('Appearance', isDarkMode),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark theme',
                value: isDarkMode,
                onChanged: (value) async {
                  await ref.read(themeModeProvider.notifier).toggleTheme();
                },
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildNavigationTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: _selectedLanguage,
                onTap: () => _showLanguagePicker(),
                isDarkMode: isDarkMode,
              ),
            ], isDarkMode),
            const SizedBox(height: 24),

            // Account Preferences
            _buildSectionTitle('Account Preferences', isDarkMode),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.lock_outline,
                title: 'Private Account',
                subtitle: 'Only approved followers can see your content',
                value: _isPrivateAccount,
                onChanged: (value) => setState(() => _isPrivateAccount = value),
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive push notifications',
                value: _isNotificationsEnabled,
                onChanged: (value) =>
                    setState(() => _isNotificationsEnabled = value),
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildNavigationTile(
                icon: Icons.block,
                title: 'Blocked Accounts',
                subtitle: 'Manage blocked users',
                onTap: () {},
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildNavigationTile(
                icon: Icons.person_remove,
                title: 'Restricted Accounts',
                subtitle: 'Manage restricted users',
                onTap: () {},
                isDarkMode: isDarkMode,
              ),
            ], isDarkMode),
            const SizedBox(height: 24),

            // Data & Storage
            _buildSectionTitle('Data & Storage', isDarkMode),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildNavigationTile(
                icon: Icons.storage,
                title: 'Data Usage',
                subtitle: 'Manage data and storage settings',
                onTap: () {},
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildNavigationTile(
                icon: Icons.high_quality,
                title: 'Video Quality',
                subtitle: _selectedVideoQuality,
                onTap: () => _showVideoQualityPicker(),
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildNavigationTile(
                icon: Icons.download,
                title: 'Downloads',
                subtitle: 'Manage downloaded content',
                onTap: () {},
                isDarkMode: isDarkMode,
              ),
            ], isDarkMode),
            const SizedBox(height: 24),

            // Security
            _buildSectionTitle('Security', isDarkMode),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildSwitchTile(
                icon: Icons.security,
                title: 'Two-Factor Authentication',
                subtitle: 'Add an extra layer of security',
                value: _isTwoFactorAuth,
                onChanged: (value) {
                  setState(() => _isTwoFactorAuth = value);
                  if (value) {
                    Navigator.pushNamed(context, NamedRoutes.twoFactorScreen);
                  }
                },
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildNavigationTile(
                icon: Icons.password,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () => Navigator.pushNamed(
                    context, NamedRoutes.changePasswordScreen),
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildNavigationTile(
                icon: Icons.devices,
                title: 'Active Sessions',
                subtitle: 'Manage where you\'re logged in',
                onTap: () => Navigator.pushNamed(
                    context, NamedRoutes.activeSessionsScreen),
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildNavigationTile(
                icon: Icons.fingerprint,
                title: 'App Lock',
                subtitle: 'Secure app with biometric or PIN',
                onTap: () =>
                    Navigator.pushNamed(context, NamedRoutes.lockScreenScreen),
                isDarkMode: isDarkMode,
              ),
            ], isDarkMode),
            const SizedBox(height: 24),

            // Subscription
            _buildSectionTitle('Subscription', isDarkMode),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildNavigationTile(
                icon: Icons.workspace_premium,
                title: 'clique Premium',
                subtitle: 'Unlock exclusive features',
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.pink],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: AppTheme.whiteTextStyle.copyWith(
                      fontSize: 10,
                      fontWeight: AppTheme.bold,
                    ),
                  ),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SubscribePage()),
                  );
                },
                isDarkMode: isDarkMode,
              ),
            ], isDarkMode),
            const SizedBox(height: 24),

            // About section
            _buildSectionTitle('About', isDarkMode),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildNavigationTile(
                icon: Icons.info_outline,
                title: 'About Clique',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, NamedRoutes.aboutScreen);
                },
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildNavigationTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Read our terms and conditions',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, NamedRoutes.termsScreen);
                },
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildNavigationTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, NamedRoutes.privacyScreen);
                },
                isDarkMode: isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildNavigationTile(
                icon: Icons.help_outline,
                title: 'Help Center',
                subtitle: 'Get help and support',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, NamedRoutes.helpScreen);
                },
                isDarkMode: isDarkMode,
              ),
            ], isDarkMode),
            const SizedBox(height: 24),

            // Logout button
            GestureDetector(
              onTap: _showLogoutDialog,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.redColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Logout',
                    style: AppTheme.blackTextStyle.copyWith(
                      color: AppColors.redColor,
                      fontWeight: AppTheme.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
      String userName, String userAvatar, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<ProfileBloc>()),
                BlocProvider(create: (context) => GalleryProfileCubit()),
              ],
              child: const ProfilePage(isOwnProfile: true),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(userAvatar, userName,
                size: 60, isDarkMode: isDarkMode),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: AppTheme.blackTextStyle.copyWith(
                      fontWeight: AppTheme.bold,
                      fontSize: 18,
                      color:
                          isDarkMode ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View your profile',
                    style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.greyColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String avatar, String name,
      {required double size, required bool isDarkMode}) {
    final fallbackText = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    if (avatar.isNotEmpty && avatar.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _avatarFallback(size, fallbackText, isDarkMode),
        ),
      );
    }

    if (avatar.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _avatarFallback(size, fallbackText, isDarkMode),
        ),
      );
    }

    return _avatarFallback(size, fallbackText, isDarkMode);
  }

  Widget _avatarFallback(double size, String fallbackText, bool isDarkMode) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Center(
        child: Text(
          fallbackText,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTheme.blackTextStyle.copyWith(
          fontWeight: AppTheme.bold,
          fontSize: 16,
          color: isDarkMode ? AppColors.darkText : AppColors.lightText,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? AppColors.darkBorderColor
              : AppColors.lightBorderColor.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: AppTheme.blackTextStyle.copyWith(
          fontWeight: AppTheme.medium,
          color: isDarkMode ? AppColors.darkText : AppColors.lightText,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: AppTheme.blackTextStyle.copyWith(
          fontWeight: AppTheme.medium,
          color: isDarkMode ? AppColors.darkText : AppColors.lightText,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
      ),
      trailing: trailing ??
          Icon(Icons.chevron_right, color: AppColors.greyColor, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      indent: 56,
      color: isDarkMode ? AppColors.darkTextHint : AppColors.lightDivider,
    );
  }

  void _showLanguagePicker() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final languages = [
          'English',
          'Spanish',
          'French',
          'German',
          'Portuguese',
          'Chinese'
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppColors.greyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 30),
              ...languages.map((language) => ListTile(
                    title: Text(
                      language,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black),
                    ),
                    trailing: _selectedLanguage == language
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedLanguage = language);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(
                height: 30,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVideoQualityPicker() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final qualities = ['Auto', 'Low 480p', 'HD 720p', 'HD 1080p', '4K'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: AppColors.greyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ...qualities.map((quality) => ListTile(
                    title: Text(quality,
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black)),
                    trailing: _selectedVideoQuality == quality
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedVideoQuality = quality);
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

  void _showLogoutDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: AppTheme.blackTextStyle.copyWith(fontWeight: AppTheme.bold)),
        content: Text('Are you sure you want to log out?',
            style: AppTheme.greyTextStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.greyColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(SignOutRequested());
            },
            child: Text('Logout',
                style: TextStyle(
                    color: AppColors.redColor, fontWeight: AppTheme.bold)),
          ),
        ],
      ),
    );
  }
}
