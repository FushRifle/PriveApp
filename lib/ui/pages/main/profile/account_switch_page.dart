import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/profile/profile_bloc.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/local_cache/local_cache_service.dart';
import 'package:clique/core/services/user/user_service.dart';

class AccountSwitchPage extends StatefulWidget {
  final bool isSheet;

  const AccountSwitchPage({
    super.key,
    this.isSheet = false,
  });

  @override
  State<AccountSwitchPage> createState() => _AccountSwitchPageState();
}

class _AccountSwitchPageState extends State<AccountSwitchPage> {
  final UserService _userService = UserService();

  bool _isLoading = true;
  bool _isSwitching = false;
  int? _activeProfileUserId;
  List<Map<String, dynamic>> _profiles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _userService.getProfileSwitchState();
      final rawProfiles = response['profiles'];
      final profiles = <Map<String, dynamic>>[];

      if (rawProfiles is List) {
        for (final item in rawProfiles) {
          if (item is Map) {
            profiles.add(Map<String, dynamic>.from(item));
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _activeProfileUserId = _readInt(response['activeProfileId']);
        _profiles = profiles;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _switchProfile(int profileUserId) async {
    if (_isSwitching) return;

    setState(() {
      _isSwitching = true;
    });

    try {
      await _userService.switchProfile(profileUserId);
      await LocalCacheService.clearAll();

      if (!mounted) return;

      context.read<UserBloc>().add(RefreshCurrentUser());
      context.read<ProfileBloc>().add(RefreshMyProfile());
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account switched'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSwitching = false;
        });
      }
    }
  }

  Future<void> _openLinkedProfile(Map<String, dynamic> profile) async {
    final profileUserId = _readInt(profile['id']);
    if (profileUserId <= 0) return;
    final isActive = profile['isActive'] == true ||
        (_activeProfileUserId != null && profileUserId == _activeProfileUserId);
    if (isActive) return;

    await _switchProfile(profileUserId);
  }

  Future<void> _showAddAccountSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_rounded),
                title: const Text('Create new profile'),
                subtitle: const Text('Add a fresh profile to this account'),
                onTap: () => Navigator.pop(context, 'create'),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'create') {
      await _createProfile();
    }
  }

  Future<void> _createProfile() async {
    final result = await showModalBottomSheet<_CreateProfileData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreateProfileSheet(),
    );
    if (result == null) return;

    setState(() => _isSwitching = true);
    try {
      await _userService.createProfile(
        name: result.name,
        username: result.username,
        profileType: result.profileType,
      );
      await LocalCacheService.clearAll();
      if (!mounted) return;
      context.read<UserBloc>().add(RefreshCurrentUser());
      context.read<ProfileBloc>().add(RefreshMyProfile());
      await _loadProfiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSwitching = false);
    }
  }

  Future<void> _deleteProfile(Map<String, dynamic> profile) async {
    final profileUserId = _readInt(profile['id']);
    if (profileUserId <= 0 || profile['isActive'] == true) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text(
          'This removes ${profile['name'] ?? 'this profile'} and its linked profile record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSwitching = true);
    try {
      await _userService.deleteProfile(profileUserId);
      await LocalCacheService.clearAll();
      await _loadProfiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSwitching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.settingsLightBackground,
      appBar: widget.isSheet
          ? null
          : AppBar(
              backgroundColor: AppColors.transparent,
              elevation: 1,
              centerTitle: true,
              title: Text(
                'Switch Account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _loadProfiles,
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
              ],
            ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, widget.isSheet ? 10 : 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isSheet) ...[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.white24 : AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Switch account',
                        style: AppTheme.blackTextStyle.copyWith(
                          color: isDark ? AppColors.white : AppColors.black,
                          fontWeight: AppTheme.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _loadProfiles,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              _Header(
                count: _profiles.length,
                isDark: isDark,
                onCreate: _showAddAccountSheet,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _ErrorState(
                            error: _error!,
                            onRetry: _loadProfiles,
                            isDark: isDark,
                          )
                        : _profiles.isEmpty
                            ? _EmptyState(isDark: isDark)
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: _profiles.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final profile = _profiles[index];
                                  return _ProfileCard(
                                    profile: profile,
                                    isActive: profile['isActive'] == true ||
                                        (_activeProfileUserId != null &&
                                            _readInt(profile['id']) ==
                                                _activeProfileUserId),
                                    isDark: isDark,
                                    isSwitching: _isSwitching,
                                    onTap: () => _openLinkedProfile(profile),
                                    onDelete: () => _deleteProfile(profile),
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

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _Header extends StatelessWidget {
  final int count;
  final bool isDark;
  final VoidCallback onCreate;

  const _Header({
    required this.count,
    required this.isDark,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.white10 : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.switch_account_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Linked accounts',
                  style: AppTheme.blackTextStyle.copyWith(
                    color: AppColors.text,
                    fontWeight: AppTheme.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  //count == 0
                  //  ? 'No linked profiles available'
                  //: '$count linked profile${count == 1 ? '' : 's'}',
                  'Coming Soon.',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          // IconButton.filled(
          // onPressed: onCreate,
          //icon: const Icon(Icons.add_rounded),
          //),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final bool isActive;
  final bool isDark;
  final bool isSwitching;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.isDark,
    required this.isSwitching,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        _readString(profile['name'] ?? profile['displayName']) ?? 'User';
    final username = _readString(profile['username']) ??
        _readString(profile['email']) ??
        '@user';
    final avatar = _readString(profile['avatar']) ?? '';
    final profileType = _readString(profile['profileType']) ?? 'personal';

    return InkWell(
      onTap: isActive || isSwitching ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.08)
              : (isDark ? AppColors.darkCard : AppColors.card),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withOpacity(0.28)
                : (isDark ? AppColors.white10 : AppColors.border),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              backgroundImage:
                  avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
              child: avatar.isEmpty
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'U',
                      style: AppTheme.blackTextStyle.copyWith(
                        fontWeight: AppTheme.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTheme.blackTextStyle.copyWith(
                      color: isDark ? AppColors.white : AppColors.black,
                      fontWeight: AppTheme.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    username,
                    style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profileType[0].toUpperCase() + profileType.substring(1),
                    style: AppTheme.greyTextStyle.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Active',
                  style: AppTheme.blackTextStyle.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (isSwitching)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete profile'),
                  ),
                ],
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.greyColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;
    return text;
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.switch_account_outlined,
            size: 54,
            color: isDark ? AppColors.white30 : AppColors.greyColor,
          ),
          const SizedBox(height: 14),
          Text(
            'No linked profiles yet',
            style: AppTheme.blackTextStyle.copyWith(
              color: isDark ? AppColors.white : AppColors.black,
              fontWeight: AppTheme.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add another profile to switch between accounts here.',
            textAlign: TextAlign.center,
            style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorState({
    required this.error,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 54,
            color: AppColors.redColor,
          ),
          const SizedBox(height: 14),
          Text(
            'Unable to load accounts',
            style: AppTheme.blackTextStyle.copyWith(
              color: isDark ? AppColors.white : AppColors.black,
              fontWeight: AppTheme.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _CreateProfileData {
  final String name;
  final String username;
  final String profileType;

  const _CreateProfileData({
    required this.name,
    required this.username,
    required this.profileType,
  });
}

class _CreateProfileSheet extends StatefulWidget {
  const _CreateProfileSheet();

  @override
  State<_CreateProfileSheet> createState() => _CreateProfileSheetState();
}

class _CreateProfileSheetState extends State<_CreateProfileSheet> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  String _profileType = 'personal';

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add another account',
                style: AppTheme.blackTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: AppTheme.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Account name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Account username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'personal',
                    label: Text('Personal'),
                    icon: Icon(Icons.person_outline_rounded),
                  ),
                  ButtonSegment(
                    value: 'business',
                    label: Text('Business'),
                    icon: Icon(Icons.storefront_outlined),
                  ),
                  ButtonSegment(
                    value: 'creator',
                    label: Text('Creator'),
                    icon: Icon(Icons.auto_awesome_outlined),
                  ),
                ],
                selected: {_profileType},
                onSelectionChanged: (selection) {
                  setState(() => _profileType = selection.first);
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Add account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    if (name.isEmpty || username.isEmpty) return;

    Navigator.pop(
      context,
      _CreateProfileData(
        name: name,
        username: username,
        profileType: _profileType,
      ),
    );
  }
}
