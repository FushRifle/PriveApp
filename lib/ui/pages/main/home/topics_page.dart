import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:clique/ui/widgets/post/normal-post/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key});

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  final FeedService _feedService = FeedService();
  final ScrollController _scrollController = ScrollController();

  final List<String> _fallbackTopics = const [
    'flutter',
    'technology',
    'design',
    'business',
    'music',
    'sports',
    'gaming',
    'startups',
  ];

  final List<String> _topics = [];
  final List<FeedPost> _posts = [];

  bool _loadingTopics = true;
  bool _loadingPosts = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String? _selectedTopic;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTopics();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _loadingTopics = true;
      _error = null;
    });

    try {
      final trending = await _feedService.getTrendingHashtags(limit: 20);
      final topicValues = trending
          .map((item) => item['tag']?.toString().trim().toLowerCase() ?? '')
          .where((tag) => tag.isNotEmpty)
          .toList();

      final topics = topicValues.isNotEmpty ? topicValues : _fallbackTopics;

      if (!mounted) return;

      setState(() {
        _topics
          ..clear()
          ..addAll(topics);
        _selectedTopic = _topics.first;
      });

      await _loadPosts(refresh: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingTopics = false;
        });
      }
    }
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    final topic = _selectedTopic;
    if (topic == null || topic.isEmpty) return;

    if (_loadingPosts || _loadingMore) return;

    if (refresh) {
      setState(() {
        _loadingPosts = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() {
        _loadingMore = true;
      });
    }

    try {
      final response = await _feedService.getPostsByHashtag(
        tag: topic,
        page: refresh ? 1 : _page + 1,
      );

      if (!mounted) return;

      setState(() {
        if (refresh) {
          _posts
            ..clear()
            ..addAll(response.posts);
          _page = 1;
        } else {
          final existingIds = _posts.map((post) => post.id).toSet();
          _posts.addAll(
            response.posts.where((post) => !existingIds.contains(post.id)),
          );
          _page += 1;
        }
        _hasMore = response.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingPosts = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadTopics();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || !_hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 500) {
      _loadPosts();
    }
  }

  void _selectTopic(String topic) {
    if (_selectedTopic == topic) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedTopic = topic;
      _posts.clear();
      _page = 1;
      _hasMore = false;
    });
    _loadPosts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.secondary,
          backgroundColor: isDark ? AppColors.cardColor : AppColors.white,
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _TopicsHero(
                  onBack: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: _TopicStrip(
                  topics: _topics,
                  selectedTopic: _selectedTopic,
                  loading: _loadingTopics,
                  onSelectTopic: _selectTopic,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                  child: _TopicMeta(
                    topic: _selectedTopic,
                    count: _posts.length,
                    loading: _loadingPosts,
                  ),
                ),
              ),
              if (_loadingTopics && _posts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else if (_error != null && _posts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _TopicsError(
                    error: _error!,
                    onRetry: _loadTopics,
                  ),
                )
              else if (_posts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _TopicsEmpty(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return BlocProvider.value(
                        value: context.read<FeedBloc>(),
                        child: CardPost(post: post),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemCount: _posts.length,
                  ),
                ),
              if (_loadingMore)
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 20),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicsHero extends StatelessWidget {
  final VoidCallback onBack;

  const _TopicsHero({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background.withOpacity(0.95),
              AppColors.card.withOpacity(0.88),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Topics',
                    style: AppTheme.blackTextStyle.copyWith(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Explore what the network is talking about right now.',
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.white,
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a topic to see the latest posts, reactions, and conversations.',
              style: AppTheme.greyTextStyle.copyWith(
                color: AppColors.white.withOpacity(0.88),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicStrip extends StatelessWidget {
  final List<String> topics;
  final String? selectedTopic;
  final bool loading;
  final ValueChanged<String> onSelectTopic;

  const _TopicStrip({
    required this.topics,
    required this.selectedTopic,
    required this.loading,
    required this.onSelectTopic,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && topics.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final topic = topics[index];
          final selected = topic == selectedTopic;

          return GestureDetector(
            onTap: () => onSelectTopic(topic),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.cardColor.withOpacity(0.96),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.cardBorderColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: selected ? AppColors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '#$topic',
                    style: AppTheme.blackTextStyle.copyWith(
                      color: selected ? AppColors.white : AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: topics.length,
      ),
    );
  }
}

class _TopicMeta extends StatelessWidget {
  final String? topic;
  final int count;
  final bool loading;

  const _TopicMeta({
    required this.topic,
    required this.count,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final label = topic == null ? 'Topics' : '#$topic';
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTheme.blackTextStyle.copyWith(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (loading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          )
        else
          Text(
            '$count posts',
            style: AppTheme.greyTextStyle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _TopicsError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _TopicsError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load topics',
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicsEmpty extends StatelessWidget {
  const _TopicsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tag_rounded,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts for this topic yet',
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try another topic or come back later for fresh posts.',
              textAlign: TextAlign.center,
              style: AppTheme.greyTextStyle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
