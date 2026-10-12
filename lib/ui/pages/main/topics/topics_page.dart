import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/core/models/feeds_models.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:clique/ui/pages/main/topics/topic_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      setState(() {});
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
      setState(() {});
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

  void _openTopicDetails(String topic) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicDetailsPage(topic: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
        ),
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topics',
              style: AppTheme.blackTextStyle.copyWith(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _loadingTopics
                  ? 'Finding conversations…'
                  : '${_topics.length} conversations trending',
              style: AppTheme.greyTextStyle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.secondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'What people are talking about now',
                        style: AppTheme.blackTextStyle.copyWith(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _TopicTrendList(
              topics: _topics,
              selectedTopic: _selectedTopic,
              loading: _loadingTopics,
              onSelectTopic: _selectTopic,
              onOpenTopic: _openTopicDetails,
            ),
            if (_loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
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
    );
  }
}

class _TopicTrendList extends StatelessWidget {
  final List<String> topics;
  final String? selectedTopic;
  final bool loading;
  final ValueChanged<String> onSelectTopic;
  final ValueChanged<String> onOpenTopic;

  const _TopicTrendList({
    required this.topics,
    required this.selectedTopic,
    required this.loading,
    required this.onSelectTopic,
    required this.onOpenTopic,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && topics.isEmpty) {
      return SliverList.builder(
        itemCount: 7,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: topics.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 68,
        endIndent: 18,
        color: AppColors.cardBorder.withOpacity(0.45),
      ),
      itemBuilder: (_, index) => _TrendTile(
        topic: topics[index],
        index: index,
        selected: topics[index] == selectedTopic,
        accent: _topicAccent(index),
        onTap: () {
          onSelectTopic(topics[index]);
          onOpenTopic(topics[index]);
        },
      ),
    );
  }
}

class _TrendTile extends StatelessWidget {
  final String topic;
  final int index;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _TrendTile({
    required this.topic,
    required this.index,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.055) : AppColors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                index < 3
                    ? Icons.local_fire_department_rounded
                    : Icons.tag_rounded,
                color: index < 3 ? accent : AppColors.secondary,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#$topic',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.blackTextStyle.copyWith(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    index < 3
                        ? 'Popular right now'
                        : 'Explore the conversation',
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
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              color: selected ? accent : AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
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
