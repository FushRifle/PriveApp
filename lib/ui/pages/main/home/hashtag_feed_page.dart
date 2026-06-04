import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/bloc/home/feed_bloc.dart';
import 'package:clique/data/models/feeds_models.dart';
import 'package:clique/data/services/home/feed_service.dart';
import 'package:clique/ui/widgets/post/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HashtagFeedPage extends StatefulWidget {
  final String tag;

  const HashtagFeedPage({
    super.key,
    required this.tag,
  });

  @override
  State<HashtagFeedPage> createState() => _HashtagFeedPageState();
}

class _HashtagFeedPageState extends State<HashtagFeedPage> {
  final FeedService _feedService = FeedService();
  final ScrollController _scrollController = ScrollController();

  final List<FeedPost> _posts = [];

  int _page = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  String get _tag => widget.tag.replaceFirst('#', '').trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPosts(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 500) {
      _loadPosts();
    }
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (_isLoadingMore && !refresh) return;

    setState(() {
      if (refresh) {
        _isLoading = true;
        _page = 1;
        _hasMore = true;
      } else {
        _isLoadingMore = true;
      }
      _error = null;
    });

    try {
      final response = await _feedService.getPostsByHashtag(
        tag: _tag,
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
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FeedBloc(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.cardColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_new),
            color: AppColors.blackTextColor,
          ),
          title: Text(
            '#$_tag',
            style: AppTheme.blackTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _loadPosts(refresh: true),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_error != null && _posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 160),
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.greyColor,
            size: 42,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error!,
              style: AppTheme.greyTextStyle,
            ),
          ),
        ],
      );
    }

    if (_posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          Icon(
            Icons.tag_rounded,
            color: AppColors.greyColor,
            size: 52,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'No posts for #$_tag yet',
              style: AppTheme.greyTextStyle,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _posts.length) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }

        return CardPost(
          key: ValueKey('hashtag_${_posts[index].id}'),
          post: _posts[index],
        );
      },
    );
  }
}
