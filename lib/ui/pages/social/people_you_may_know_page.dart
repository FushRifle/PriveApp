import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/user/user_bloc.dart';
import 'package:clique/core/router/named_routes.dart';
import 'package:clique/core/services/friends/friends_service.dart';
import 'package:clique/core/services/user/user_service.dart';
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
  final Set<int> _following = {};

  late Future<List<_SuggestedUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSuggestions();
  }

  Future<List<_SuggestedUser>> _loadSuggestions() async {
    final currentUser = context.read<UserBloc>().state.currentUser;
    final currentUserId = _readInt(currentUser?['id']);
    final raw = await _userService.getUserSuggestions(limit: 60);

    return raw
        .map(_SuggestedUser.fromJson)
        .where((user) => user.id > 0)
        .where((user) => user.id != currentUserId)
        .where((user) => !user.isFollowing)
        .toList();
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

  void _openProfile(int userId) {
    if (userId <= 0) return;
    Navigator.pushNamed(
      context,
      NamedRoutes.otherProfileScreen,
      arguments: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'People you may know',
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<_SuggestedUser>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _StateList(
              icon: Icons.error_outline_rounded,
              title: 'Could not load suggestions',
              subtitle: snapshot.error.toString(),
              onRefresh: _refresh,
            );
          }

          final suggestions = snapshot.data ?? const <_SuggestedUser>[];
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
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final person = suggestions[index];
                final followed = _following.contains(person.id);
                return _SuggestionTile(
                  person: person,
                  followed: followed,
                  onOpen: () => _openProfile(person.id),
                  onFollow: () {
                    HapticFeedback.lightImpact();
                    _follow(person);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final _SuggestedUser person;
  final bool followed;
  final VoidCallback onOpen;
  final VoidCallback onFollow;

  const _SuggestionTile({
    required this.person,
    required this.followed,
    required this.onOpen,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorderColor),
          ),
          child: Row(
            children: [
              _Avatar(person: person),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      person.username.isEmpty
                          ? 'View profile'
                          : '@${person.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                    ),
                    if (person.mutualConnections > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${person.mutualConnections} mutual connections',
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
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: followed ? null : onFollow,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.textHint,
                  minimumSize: const Size(88, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(followed ? 'Following' : 'Follow'),
              ),
            ],
          ),
        ),
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

    return ClipOval(
      child: SizedBox(
        width: 52,
        height: 52,
        child: person.avatar.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: person.avatar,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _fallback(fallback),
                placeholder: (_, __) => _fallback(fallback),
              )
            : _fallback(fallback),
      ),
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
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SuggestedUser {
  final int id;
  final String name;
  final String username;
  final String avatar;
  final bool isFollowing;
  final int mutualConnections;

  const _SuggestedUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
    required this.isFollowing,
    required this.mutualConnections,
  });

  factory _SuggestedUser.fromJson(Map<String, dynamic> json) {
    return _SuggestedUser(
      id: _readInt(json['id'] ?? json['userId'] ?? json['user_id']),
      name: (json['name'] ?? json['displayName'] ?? json['username'] ?? 'User')
          .toString(),
      username: (json['username'] ?? json['handle'] ?? '').toString(),
      avatar: (json['avatar'] ?? json['avatarUrl'] ?? '').toString(),
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
}
