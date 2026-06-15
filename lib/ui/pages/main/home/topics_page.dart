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
      _error = null;
    });
    _loadPosts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
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
                  topicCount: _topics.length,
                  postCount: _posts.length,
                  hasMore: _hasMore,
                  onBack: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 15),
                  child: _SectionLabel(
                    title: 'Trending topics',
                    subtitle: 'Tap a card to jump into the latest conversation.',
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _TopicRail(
                  topics: _topics,
                  selectedTopic: _selectedTopic,
                  loading: _loadingTopics,
                  onSelectTopic: _selectTopic,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: _TopicSummary(
                    topic: _selectedTopic,
                    count: _posts.length,
                    loading: _loadingPosts,
                    hasMore: _hasMore,
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
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
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
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicsHero extends StatelessWidget {
  final int topicCount;
  final int postCount;
  final bool hasMore;
  final VoidCallback onBack;

  const _TopicsHero({
    required this.topicCount,
    required this.postCount,
    required this.hasMore,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
      child: Container(
        width: double.infinity,
        decoration:
            _panelDecoration(radius: 28, fill: AppColors.cardColor, shadow: 0.2),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorderColor),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.text,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.cardBorderColor),
                    ),
                    child: Text(
                      'Topics',
                      style: AppTheme.blackTextStyle.copyWith(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Explore what the network is talking about right now.',
                style: AppTheme.blackTextStyle.copyWith(
                  color: AppColors.text,
                  fontSize: 20,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Switch topics fast, see the latest posts, and keep the feed moving without leaving the page.',
                style: AppTheme.greyTextStyle.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.blackTextStyle.copyWith(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTheme.greyTextStyle.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TopicRail extends StatelessWidget {
  final List<String> topics;
  final String? selectedTopic;
  final bool loading;
  final ValueChanged<String> onSelectTopic;

  const _TopicRail({
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
      height: 156,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final topic = topics[index];
          final selected = topic == selectedTopic;
          final accent = _topicAccent(index);

          return GestureDetector(
            onTap: () => onSelectTopic(topic),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 190,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? accent.withOpacity(0.08) : AppColors.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? accent.withOpacity(0.45) : AppColors.cardBorderColor,
                  width: selected ? 1.2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(selected ? 0.12 : 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          size: 19,
                          color: accent,
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Active',
                            style: AppTheme.blackTextStyle.copyWith(
                              color: AppColors.text,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '#$topic',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.blackTextStyle.copyWith(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selected
                        ? 'Latest posts are loaded below.'
                        : 'Tap to explore the conversation.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.greyTextStyle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopicSummary extends StatelessWidget {
  final String? topic;
  final int count;
  final bool loading;
  final bool hasMore;

  const _TopicSummary({
    required this.topic,
    required this.count,
    required this.loading,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    final label = topic == null ? 'Topics' : '#$topic';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(radius: 22, fill: AppColors.cardColor, shadow: 0.12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.blackTextStyle.copyWith(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasMore
                      ? 'More posts are available as you scroll.'
                      : 'You are caught up on this topic.',
                  style: AppTheme.greyTextStyle.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$count',
                  style: AppTheme.blackTextStyle.copyWith(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'posts',
                  style: AppTheme.greyTextStyle.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
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
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
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
              'Try another topic or pull to refresh for new conversations.',
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

BoxDecoration _panelDecoration({
  required double radius,
  required Color fill,
  required double shadow,
}) {
  return BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.cardBorderColor),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow.withOpacity(shadow),
        blurRadius: 14,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

Color _topicAccent(int index) {
  const colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.githubPurple,
    AppColors.githubOrange,
    AppColors.githubGreen,
    AppColors.indigo,
    AppColors.cyan,
    AppColors.pink,
  ];

  return colors[index % colors.length];
}
