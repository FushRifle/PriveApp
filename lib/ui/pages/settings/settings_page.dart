import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/app/resources/constant/named_routes.dart';
import 'package:Prive/ui/pages/settings/subscribe_page.dart';
import 'package:Prive/data/services/user/user_service.dart';
import 'package:Prive/data/hooks/auth/auth_hook.dart';
import 'package:Prive/data/providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final AuthHook _authHook = AuthHook();
  final UserService _userService = UserService();

  bool _isLoading = true;
  Map<String, dynamic> _user = {};
  String? _error;

  bool _isNotificationsEnabled = true;
  bool _isPrivateAccount = false;
  bool _isTwoFactorAuth = false;
  String _selectedLanguage = 'English';
  String _selectedVideoQuality = 'HD 1080p';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _authHook.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await _userService.getCurrentUser();
      setState(() {
        _user = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final userName = _user['name'] ?? _user['username'] ?? 'User';
    final userAvatar = _user['avatar'] ?? _user['avatar_url'] ?? '';
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: AppTheme.greyTextStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile section with real user data
                        _buildProfileSection(userName, userAvatar),
                        const SizedBox(height: 24),

                        // Appearance
                        _buildSectionTitle('Appearance'),
                        const SizedBox(height: 8),
                        _buildSettingsCard([
                          _buildSwitchTile(
                            icon: Icons.dark_mode,
                            title: 'Dark Mode',
                            subtitle: 'Switch between light and dark theme',
                            value: isDarkMode,
                            onChanged: (value) async {
                              await ref
                                  .read(themeModeProvider.notifier)
                                  .toggleTheme();
                            },
                          ),
                          _buildDivider(),
                          _buildNavigationTile(
                            icon: Icons.language,
                            title: 'Language',
                            subtitle: _selectedLanguage,
                            onTap: () => _showLanguagePicker(),
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Account Preferences
                        _buildSectionTitle('Account Preferences'),
                        const SizedBox(height: 8),
                        _buildSettingsCard([
                          _buildSwitchTile(
                            icon: Icons.lock_outline,
                            title: 'Private Account',
                            subtitle:
                                'Only approved followers can see your content',
                            value: _isPrivateAccount,
                            onChanged: (value) {
                              setState(() {
                                _isPrivateAccount = value;
                              });
                            },
                          ),
                          _buildDivider(),
                          _buildSwitchTile(
                            icon: Icons.notifications_outlined,
                            title: 'Push Notifications',
                            subtitle: 'Receive push notifications',
                            value: _isNotificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _isNotificationsEnabled = value;
                              });
                            },
                          ),
                          _buildDivider(),
                          _buildNavigationTile(
                            icon: Icons.block,
                            title: 'Blocked Accounts',
                            subtitle: 'Manage blocked users',
                            onTap: () {
                              // TODO: Navigate to blocked accounts
                            },
                          ),
                          _buildDivider(),
                          _buildNavigationTile(
                            icon: Icons.person_remove,
                            title: 'Restricted Accounts',
                            subtitle: 'Manage restricted users',
                            onTap: () {
                              // TODO: Navigate to restricted accounts
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Data & Storage
                        _buildSectionTitle('Data & Storage'),
                        const SizedBox(height: 8),
                        _buildSettingsCard([
                          _buildNavigationTile(
                            icon: Icons.storage,
                            title: 'Data Usage',
                            subtitle: 'Manage data and storage settings',
                            onTap: () {
                              // TODO: Navigate to data settings
                            },
                          ),
                          _buildDivider(),
                          _buildNavigationTile(
                            icon: Icons.high_quality,
                            title: 'Video Quality',
                            subtitle: _selectedVideoQuality,
                            onTap: () => _showVideoQualityPicker(),
                          ),
                          _buildDivider(),
                          _buildNavigationTile(
                            icon: Icons.download,
                            title: 'Downloads',
                            subtitle: 'Manage downloaded content',
                            onTap: () {
                              // TODO: Navigate to downloads
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Security
                        _buildSectionTitle('Security'),
                        const SizedBox(height: 8),
                        _buildSettingsCard([
                          _buildSwitchTile(
                            icon: Icons.security,
                            title: 'Two-Factor Authentication',
                            subtitle: 'Add an extra layer of security',
                            value: _isTwoFactorAuth,
                            onChanged: (value) {
                              setState(() {
                                _isTwoFactorAuth = value;
                              });
                            },
                          ),
                          _buildDivider(),
                          _buildNavigationTile(
                            icon: Icons.password,
                            title: 'Change Password',
                            subtitle: 'Update your password',
                            onTap: () {
                              // TODO: Navigate to change password
                            },
                          ),
                          _buildDivider(),
                          _buildNavigationTile(
                            icon: Icons.devices,
                            title: 'Active Sessions',
                            subtitle: 'Manage where you\'re logged in',
                            onTap: () {
                              // TODO: Navigate to active sessions
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Subscription
                        _buildSectionTitle('Subscription'),
                        const SizedBox(height: 8),
                        _buildSettingsCard([
                          _buildNavigationTile(
                            icon: Icons.workspace_premium,
                            title: 'Prive Premium',
                            subtitle: 'Unlock exclusive features',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
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
                                  builder: (context) => const SubscribePage(),
                                ),
                              );
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // About
                        _buildSectionTitle('About'),
                        const SizedBox(height: 8),
                        _buildSettingsCard([
                          _buildNavigationTile(
                            icon: Icons.info_outline,
                            title: 'About Prive',
                            subtitle: 'Version 1.0.0',
                            onTap: () {
                              // TODO: Show about dialog
                            },
                          ),
                          _buildDivider(),
                          _buildNavigationTile(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            subtitle: 'Read our terms and conditions',
                            onTap: () {
                              // TODO: Show terms
                            },
                          ),
                          _buildDivider(),
                          _buildNavigationTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'How we handle your data',
                            onTap: () {
                              // TODO: Show privacy policy
                            },
                          ),
                          _buildDivider(),
                          _buildNavigationTile(
                            icon: Icons.help_outline,
                            title: 'Help Center',
                            subtitle: 'Get help and support',
                            onTap: () {
                              // TODO: Navigate to help center
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Logout button
                        GestureDetector(
                          onTap: () {
                            _showLogoutDialog();
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                ),
    );
  }

  Widget _buildProfileSection(String userName, String userAvatar) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, NamedRoutes.profileScreen);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
                image: userAvatar.isNotEmpty
                    ? DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(userAvatar),
                      )
                    : const DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage('assets/images/img_profile.jpeg'),
                      ),
              ),
            ),
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
            Icon(
              Icons.chevron_right,
              color: AppColors.greyColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTheme.blackTextStyle.copyWith(
          fontWeight: AppTheme.bold,
          fontSize: 16,
          color: AppColors.blackColor,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(
        title,
        style: AppTheme.blackTextStyle.copyWith(
          fontWeight: AppTheme.medium,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(
        title,
        style: AppTheme.blackTextStyle.copyWith(
          fontWeight: AppTheme.medium,
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

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      color: AppColors.greyColor.withOpacity(0.1),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
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
          'Arabic',
          'Hindi',
          'Chinese',
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
              Text(
                'Select Language',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: AppTheme.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ...languages.map((language) => ListTile(
                    title: Text(
                      language,
                      style: AppTheme.blackTextStyle.copyWith(fontSize: 16),
                    ),
                    trailing: _selectedLanguage == language
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedLanguage = language;
                      });
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

  void _showVideoQualityPicker() {
    showModalBottomSheet(
      context: context,
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
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.greyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Video Quality',
                style: AppTheme.blackTextStyle.copyWith(
                  fontWeight: AppTheme.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              ...qualities.map((quality) => ListTile(
                    title: Text(
                      quality,
                      style: AppTheme.blackTextStyle.copyWith(fontSize: 16),
                    ),
                    trailing: _selectedVideoQuality == quality
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedVideoQuality = quality;
                      });
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Logout',
            style: AppTheme.blackTextStyle.copyWith(
              fontWeight: AppTheme.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: AppTheme.greyTextStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTheme.blackTextStyle.copyWith(
                  color: AppColors.greyColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _authHook.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    NamedRoutes.loginScreen,
                  );
                }
              },
              child: Text(
                'Logout',
                style: AppTheme.blackTextStyle.copyWith(
                  color: AppColors.redColor,
                  fontWeight: AppTheme.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
