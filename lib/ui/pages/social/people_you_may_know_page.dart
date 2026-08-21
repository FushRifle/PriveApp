import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/friends/friends_service.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PeopleYouMayKnowPage extends StatefulWidget {
  const PeopleYouMayKnowPage({super.key});

  @override
  State<PeopleYouMayKnowPage> createState() => _PeopleYouMayKnowPageState();
}

class _PeopleYouMayKnowPageState extends State<PeopleYouMayKnowPage> {
  final UserService _userService = UserService();
  final FriendsService _friendsService = FriendsService();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _following = {};
  final Set<int> _followed = {};

  late Future<List<_SuggestedUser>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _loadSuggestions();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  Future<List<_SuggestedUser>> _loadSuggestions() async {
    final currentUser = context.read<UserBloc>().state.currentUser;
    final currentUserId = _readCurrentUserId(currentUser);
    final raw = await _userService.getUserSuggestions(limit: 60);

    final seen = <int>{};
    return raw
        .map(_SuggestedUser.fromJson)
        .where((user) => user.id > 0)
        .where((user) => user.id != currentUserId)
        .where((user) => !user.isFollowing)
        .where((user) => seen.add(user.id))
        .toList()
      ..sort((a, b) {
        final mutual = b.mutualConnections.compareTo(a.mutualConnections);
        if (mutual != 0) return mutual;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadSuggestions();
    });
    await _future;
  }

  Future<void> _follow(_SuggestedUser user) async {
    if (_following.contains(user.id)) return;
    setState(() => _following.add(user.id));

    try {
      await _friendsService.followUser(user.id);
      if (!mounted) return;
      setState(() {
        _following.remove(user.id);
        _followed.add(user.id);
      });
      HapticFeedback.selectionClick();
    } catch (error) {
      if (!mounted) return;
      setState(() => _following.remove(user.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleSearchChanged() {
    final next = _searchController.text.trim().toLowerCase();
    if (next == _query) return;
    setState(() => _query = next);
  }

  void _openProfile(int userId) {
    if (userId <= 0) return;
    Navigator.pushNamed(
      context,
      NamedRoutes.otherProfileScreen,
      arguments: userId,
    );
  }

  List<_SuggestedUser> _filterSuggestions(List<_SuggestedUser> suggestions) {
    if (_query.isEmpty) return suggestions;
    return suggestions.where((user) {
      return user.name.toLowerCase().contains(_query) ||
          user.username.toLowerCase().contains(_query) ||
          user.bio.toLowerCase().contains(_query) ||
          user.location.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Discover people',
            subtitle: 'Build a circle that feels like you',
            leadingIcon: Icons.arrow_back_ios_new_rounded,
            onLeadingTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: FutureBuilder<List<_SuggestedUser>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const _LoadingList();
                }

                if (snapshot.hasError) {
                  return _StateList(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load suggestions',
                    subtitle:
                        'Check your connection, then pull down or tap below to try again.',
                    onRefresh: _refresh,
                  );
                }

                final suggestions = snapshot.data ?? const <_SuggestedUser>[];
                final filtered = _filterSuggestions(suggestions);
                if (suggestions.isEmpty) {
                  return _StateList(
                    icon: Icons.group_add_outlined,
                    title: 'No suggestions right now',
                    subtitle: 'Check back later for more people to follow.',
                    onRefresh: _refresh,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _DiscoveryHeader(
                          totalCount: suggestions.length,
                          visibleCount: filtered.length,
                          searchController: _searchController,
                          onClearSearch: () => _searchController.clear(),
                        ),
                      ),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _InlineEmptyState(
                            query: _searchController.text.trim(),
                            onClear: () => _searchController.clear(),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          sliver: SliverLayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.crossAxisExtent >= 680;
                              if (wide) {
                                return SliverGrid.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 360,
                                    mainAxisExtent: 188,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    return _SuggestionCard(
                                      person: filtered[index],
                                      following: _following.contains(
                                        filtered[index].id,
                                      ),
                                      followed: _followed
                                          .contains(filtered[index].id),
                                      onOpen: () =>
                                          _openProfile(filtered[index].id),
                                      onFollow: () {
                                        HapticFeedback.lightImpact();
                                        _follow(filtered[index]);
                                      },
                                    );
                                  },
                                );
                              }

                              return SliverList.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final person = filtered[index];
                                  return _SuggestionCard(
                                    person: person,
                                    following: _following.contains(person.id),
                                    followed: _followed.contains(person.id),
                                    onOpen: () => _openProfile(person.id),
                                    onFollow: () {
                                      HapticFeedback.lightImpact();
                                      _follow(person);
                                    },
                                  );
                                },
                              );
                            },
                          ),
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

  int _readCurrentUserId(Map<String, dynamic>? user) {
    if (user == null) return 0;
    final candidates = [
      user['id'],
      user['userId'],
      user['user_id'],
      user['profileUserId'],
      user['profile_user_id'],
      if (user['user'] is Map) (user['user'] as Map)['id'],
      if (user['profile'] is Map) (user['profile'] as Map)['userId'],
      if (user['profile'] is Map) (user['profile'] as Map)['user_id'],
      if (user['profile'] is Map) (user['profile'] as Map)['id'],
      if (user['activeProfile'] is Map)
        (user['activeProfile'] as Map)['userId'],
      if (user['activeProfile'] is Map)
        (user['activeProfile'] as Map)['user_id'],
      if (user['activeProfile'] is Map) (user['activeProfile'] as Map)['id'],
      if (user['active_profile'] is Map)
        (user['active_profile'] as Map)['userId'],
      if (user['active_profile'] is Map)
        (user['active_profile'] as Map)['user_id'],
      if (user['active_profile'] is Map) (user['active_profile'] as Map)['id'],
    ];
    for (final value in candidates) {
      final id = _readInt(value);
      if (id > 0) return id;
    }
    return 0;
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _DiscoveryHeader extends StatelessWidget {
  final int totalCount;
  final int visibleCount;
  final TextEditingController searchController;
  final VoidCallback onClearSearch;

  const _DiscoveryHeader({
    required this.totalCount,
    required this.visibleCount,
    required this.searchController,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.group_add_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$visibleCount of $totalCount suggestions',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.blackTextStyle.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Follow relevant people to improve your feed, chat suggestions, and community signals.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.greyTextStyle.copyWith(
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search name, username, bio, or location',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final _SuggestedUser person;
  final bool following;
  final bool followed;
  final VoidCallback onOpen;
  final VoidCallback onFollow;

  const _SuggestionCard({
    required this.person,
    required this.following,
    required this.followed,
    required this.onOpen,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(person: person),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            person.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.blackTextStyle.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (person.verified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      person.username.isEmpty
                          ? 'View profile'
                          : '@${person.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                    ),
                    if (person.bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        person.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.greyTextStyle.copyWith(
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (person.mutualConnections > 0)
                          _SignalChip(
                            icon: Icons.people_alt_outlined,
                            label:
                                '${person.mutualConnections} mutual connection${person.mutualConnections == 1 ? '' : 's'}',
                          ),
                        if (person.location.isNotEmpty)
                          _SignalChip(
                            icon: Icons.place_outlined,
                            label: person.location,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _FollowButton(
                following: following,
                followed: followed,
                onPressed: onFollow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool following;
  final bool followed;
  final VoidCallback onPressed;

  const _FollowButton({
    required this.following,
    required this.followed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 42,
      child: FilledButton(
        onPressed: following || followed ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.12),
          disabledForegroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: following
            ? const SizedBox.square(
                dimension: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(followed ? 'Following' : 'Follow'),
              ),
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SignalChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.greyTextStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final _SuggestedUser person;

  const _Avatar({required this.person});

  @override
  Widget build(BuildContext context) {
    final fallback = person.name.trim().isNotEmpty
        ? person.name.trim()[0].toUpperCase()
        : 'U';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: SizedBox(
            width: 58,
            height: 58,
            child: person.avatar.startsWith('http')
                ? AppNetworkImage(
                    imageUrl: person.avatar,
                    fit: BoxFit.cover,
                    preset: AppNetworkImagePreset.avatar,
                    errorBuilder: (_) => _fallback(fallback),
                    placeholder: (_) => _fallback(fallback),
                  )
                : _fallback(fallback),
          ),
        ),
        if (person.mutualConnections > 2)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.card, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback(String text) {
    return ColoredBox(
      color: AppColors.primary.withOpacity(0.10),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: index == 0 ? 126 : 116,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _SkeletonBox(
                width: index == 0 ? 48 : 58,
                height: index == 0 ? 48 : 58,
                radius: 999,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SkeletonBox(width: 160, height: 14),
                    SizedBox(height: 10),
                    _SkeletonBox(width: 120, height: 12),
                    SizedBox(height: 12),
                    _SkeletonBox(width: 220, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.55),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _StateList extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;

  const _StateList({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 120),
          Icon(icon, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => onRefresh(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              minimumSize: const Size(160, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _InlineEmptyState({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 54,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 14),
          Text(
            'No matches for "$query"',
            textAlign: TextAlign.center,
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different name, username, bio, or location.',
            textAlign: TextAlign.center,
            style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Clear search'),
          ),
        ],
      ),
    );
  }
}

class _SuggestedUser {
  final int id;
  final String name;
  final String username;
  final String avatar;
  final String bio;
  final String location;
  final bool verified;
  final bool isFollowing;
  final int mutualConnections;

  const _SuggestedUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
    required this.bio,
    required this.location,
    required this.verified,
    required this.isFollowing,
    required this.mutualConnections,
  });

  factory _SuggestedUser.fromJson(Map<String, dynamic> json) {
    return _SuggestedUser(
      id: _readInt(json['id'] ?? json['userId'] ?? json['user_id']),
      name: _readString(
        json['name'] ?? json['displayName'] ?? json['display_name'],
        fallback: _readString(json['username'], fallback: 'User'),
      ),
      username: _readString(json['username'] ?? json['handle']),
      avatar: _readString(json['avatar'] ?? json['avatarUrl']),
      bio: _readString(json['bio'] ?? json['about']),
      location: _readString(json['location'] ?? json['city']),
      verified: json['verified'] == true || json['isVerified'] == true,
      isFollowing: json['isFollowing'] == true ||
          json['following'] == true ||
          json['is_following'] == true,
      mutualConnections: _readInt(
        json['mutualConnections'] ??
            json['mutual_connections'] ??
            json['mutualCount'],
      ),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}
