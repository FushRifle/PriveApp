import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/match/match_bloc.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    context.read<MatchBloc>().add(LoadMatches());
    context.read<MatchBloc>().add(LoadRecommendations());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Matches',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.text,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'MATCHES'),
            Tab(text: 'RECOMMENDED'),
          ],
        ),
      ),
      body: BlocListener<MatchBloc, MatchState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
            context.read<MatchBloc>().add(ClearMatchError());
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMatchesList(),
            _buildRecommendationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        if (state.status == MatchStatus.loading && state.matches.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state.matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: AppColors.greyColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No matches yet',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Swipe right on recommended profiles to match!',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.matches.length,
          itemBuilder: (context, index) {
            final match = state.matches[index];
            return _buildMatchCard(match);
          },
        );
      },
    );
  }

  Widget _buildRecommendationsList() {
    return BlocBuilder<MatchBloc, MatchState>(
      builder: (context, state) {
        if (state.status == MatchStatus.loading &&
            state.recommendations.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state.recommendations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColors.greyColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No recommendations',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new people!',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.recommendations.length,
          itemBuilder: (context, index) {
            final user = state.recommendations[index];
            return _buildRecommendationCard(user);
          },
        );
      },
    );
  }

  Widget _buildMatchCard(MatchUser match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildAvatar(match.avatar, match.name, size: 55),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      match.name,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (match.isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.verified, size: 14, color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${match.username}',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                ),
                if (match.age > 0)
                  Text(
                    '${match.age} years old',
                    style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                  ),
                if (match.bio != null && match.bio!.isNotEmpty)
                  Text(
                    match.bio!,
                    style: AppTheme.greyTextStyle.copyWith(
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (match.isMutual)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Match!',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(MatchUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildAvatar(user.avatar, user.name, size: 55),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: AppTheme.blackTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.verified, size: 14, color: AppColors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username}',
                  style: AppTheme.greyTextStyle.copyWith(fontSize: 13),
                ),
                if (user.age > 0)
                  Text(
                    '${user.age} years old',
                    style: AppTheme.greyTextStyle.copyWith(fontSize: 12),
                  ),
                if (user.bio != null && user.bio!.isNotEmpty)
                  Text(
                    user.bio!,
                    style: AppTheme.greyTextStyle.copyWith(
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          BlocBuilder<MatchBloc, MatchState>(
            builder: (context, state) {
              return GestureDetector(
                onTap: state.isLiking
                    ? null
                    : () {
                        context
                            .read<MatchBloc>()
                            .add(LikeUser(userId: user.id));
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: state.isLiking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Like',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatar, String name, {required double size}) {
    final fallbackText = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    if (avatar != null && avatar.isNotEmpty && avatar.startsWith('http')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: AppColors.greyColor.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
          errorWidget: (context, url, error) =>
              _avatarFallback(size, fallbackText),
        ),
      );
    }

    return _avatarFallback(size, fallbackText);
  }

  Widget _avatarFallback(double size, String fallbackText) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
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
}
