import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:video_player/video_player.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/chat/chat_bloc.dart';
import 'package:clique/bloc/friends/friends_bloc.dart';
import 'package:clique/bloc/reels/reel_bloc.dart';
import 'package:clique/core/services/chat/chat_service.dart';
import 'package:clique/core/services/friends/friends_service.dart';
import 'package:clique/core/services/home/feed_service.dart';
import 'package:clique/core/services/reel/reel_service.dart';
import 'package:clique/core/services/user/user_service.dart';
import 'package:clique/ui/widgets/comments/comment_widgets.dart';
import 'package:clique/ui/pages/main/chat/chat_page.dart';
import 'package:clique/ui/widgets/common/token_suggestion_field.dart';
import 'package:clique/ui/widgets/common/effect_text.dart';

Future<List<ComposerTokenSuggestion>> _suggestReelComposerTokens(
  ComposerTokenType type,
  String query,
) async {
  final normalizedQuery = query.trim().toLowerCase();
  final userService = UserService();
  final feedService = FeedService();

  try {
    if (type == ComposerTokenType.mention) {
      if (normalizedQuery.isEmpty) {
        return const [];
      }

      final users = await userService.searchUsers(
        normalizedQuery,
        limit: 8,
      );

      return users
          .map((user) {
            final name = (user['name'] ?? user['displayName'] ?? 'User')
                .toString()
                .trim();
            final username =
                (user['username'] ?? user['handle'] ?? '').toString().trim();
            final bioValue = user['bio']?.toString();
            final subtitle = bioValue != null ? bioValue.trim() : '';

            return ComposerTokenSuggestion(
              value: username.isNotEmpty ? username : name.replaceAll(' ', '_'),
              label: username.isNotEmpty ? '@$username' : '@$name',
              subtitle: subtitle.isNotEmpty ? subtitle : null,
            );
          })
          .where((suggestion) => suggestion.value.isNotEmpty)
          .toList();
    }

    final hashtags = await feedService.getTrendingHashtags(limit: 12);
    final seen = <String>{};
    final values = <String>[
      ...hashtags.map((item) => item['tag']?.toString().trim() ?? ''),
      'reels',
      'video',
      'viral',
      'trending',
      'funny',
      'music',
      'dance',
      'edit',
    ]
        .where((tag) => tag.isNotEmpty)
        .where((tag) => seen.add(tag.toLowerCase()))
        .toList();

    final filtered = normalizedQuery.isEmpty
        ? values
        : values.where((tag) => tag.toLowerCase().contains(normalizedQuery));

    return filtered
        .map(
          (tag) => ComposerTokenSuggestion(
            value: tag.startsWith('#') ? tag.substring(1) : tag,
            label: '#$tag',
            subtitle: 'Hashtag',
          ),
        )
        .toList();
  } catch (_) {
    return const [];
  }
}

class ReelItem extends StatefulWidget {
  final Map<String, dynamic> reel;
  final VoidCallback onNextReel;
  final bool isActive;
  final int index;
  final int currentUserId;

  const ReelItem({
    super.key,
    required this.reel,
    required this.onNextReel,
    this.isActive = true,
    required this.index,
    required this.currentUserId,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoController;

  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasVideoError = false;
  bool _isFollowing = false;
  bool _isFollowBusy = false;
  bool _isLiked = false;
  bool _isReposted = false;
  bool _isMuted = true;

  int _localLikeDelta = 0;
  int _localCommentDelta = 0;
  int _localShareDelta = 0;
  int _localRepostDelta = 0;

  String get _videoUrl {
    final url = widget.reel['videoUrl'] ?? widget.reel['url'];
    return url?.toString() ?? '';
  }

  Map<String, dynamic> get _user {
    final user = widget.reel['user'];

    if (user is Map<String, dynamic>) {
      return user;
    }

    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }

    return {};
  }

  @override
  bool get wantKeepAlive => widget.isActive;

  @override
  void initState() {
    super.initState();

    _syncLocalState();
    _loadMutePreference();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(covariant ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.reel != widget.reel) {
      _syncLocalState();

      final oldUrl = oldWidget.reel['videoUrl'] ?? oldWidget.reel['url'];

      if (oldUrl != _videoUrl) {
        _disposeController();
        _initializeVideo();
      }
    }

    if (oldWidget.isActive != widget.isActive) {
      widget.isActive ? _playVideo() : _pauseVideo();
    }
  }

  @override
  void dispose() {
    _disposeController();

    super.dispose();
  }

  void _syncLocalState() {
    _isLiked = _readBool(widget.reel['isLiked']);
    _isReposted = _readBool(
      widget.reel['isReposted'] ?? widget.reel['is_reposted'],
    );
    _isFollowing = _readBool(
      widget.reel['isFollowing'] ?? _user['isFollowing'],
    );

    _localLikeDelta = 0;
    _localCommentDelta = 0;
    _localShareDelta = 0;
    _localRepostDelta = 0;
  }

  Future<void> _loadMutePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _isMuted = prefs.getBool('reels_muted') ?? false;
    });

    await _videoController?.setVolume(_isMuted ? 0 : 1);
  }

  Future<void> _disposeController() async {
    final controller = _videoController;

    _videoController = null;
    _isInitialized = false;
    _isPlaying = false;

    await controller?.pause();
    await controller?.dispose();
  }

  Future<void> _initializeVideo() async {
    if (_videoUrl.isEmpty) {
      if (!mounted) return;

      setState(() {
        _hasVideoError = true;
        _isInitialized = false;
      });

      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(_videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
        ),
      );

      _videoController = controller;

      await controller.initialize();

      if (!mounted || _videoController != controller) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);
      await controller.setVolume(_isMuted ? 0 : 1);

      if (widget.isActive) {
        await controller.play();
        _isPlaying = true;
      }

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _hasVideoError = false;
      });
    } catch (e) {
      debugPrint('Error initializing reel video: $e');

      if (!mounted) return;

      setState(() {
        _hasVideoError = true;
        _isInitialized = false;
        _isPlaying = false;
      });
    }
  }

  Future<void> _playVideo() async {
    final controller = _videoController;

    if (!_isInitialized || controller == null) return;

    await controller.setVolume(_isMuted ? 0 : 1);
    await controller.play();

    if (!mounted) return;

    setState(() {
      _isPlaying = true;
    });
  }

  Future<void> _pauseVideo() async {
    final controller = _videoController;

    if (!_isInitialized || controller == null) return;

    await controller.pause();
    await controller.setVolume(0);

    if (!mounted) return;

    setState(() {
      _isPlaying = false;
    });
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;

    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  Future<void> _toggleMute() async {
    final nextMuted = !_isMuted;

    setState(() {
      _isMuted = nextMuted;
    });

    await _videoController?.setVolume(nextMuted ? 0 : 1);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reels_muted', nextMuted);
  }

  void _handleLike() {
    final reelId = widget.reel['id']?.toString();

    if (reelId == null || reelId.isEmpty) return;

    final wasLiked = _isLiked;

    if (!mounted) return;

    setState(() {
      _isLiked = !wasLiked;
      _localLikeDelta += wasLiked ? -1 : 1;
    });

    if (wasLiked) {
      context.read<ReelBloc>().add(
            UnlikeReel(
              reelId: reelId,
              index: widget.index,
            ),
          );
    } else {
      context.read<ReelBloc>().add(
            LikeReel(
              reelId: reelId,
              index: widget.index,
            ),
          );
    }
  }

  void _handleComment() {
    final reelId = _reelId;

    if (reelId == null) return;

    _pauseVideo();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) {
        return _ReelCommentsSheet(
          reelId: reelId,
          onCommentAdded: () {
            if (!mounted) return;

            setState(() {
              _localCommentDelta += 1;
            });

            context.read<ReelBloc>().add(
                  IncrementReelCommentCount(
                    reelId: reelId,
                    index: widget.index,
                  ),
                );
          },
        );
      },
    ).whenComplete(() {
      if (widget.isActive) {
        _playVideo();
      }
    });
  }

  void _handleShare() {
    final reelId = widget.reel['id']?.toString();

    if (reelId == null || reelId.isEmpty) return;

    _pauseVideo();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) {
        return _ReelShareSheet(
          reel: widget.reel,
          reelId: reelId,
          onShared: () {
            if (!mounted) return;

            setState(() {
              _localShareDelta += 1;
            });

            context.read<ReelBloc>().add(
                  ShareReel(
                    reelId: reelId,
                    index: widget.index,
                  ),
                );
          },
        );
      },
    ).whenComplete(() {
      if (widget.isActive) {
        _playVideo();
      }
    });
  }

  void _handleRepost() {
    final reelId = widget.reel['id']?.toString();

    if (reelId == null || reelId.isEmpty) return;

    if (_isReposted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already reposted')),
      );
      return;
    }

    _pauseVideo();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.repeat_rounded),
                  title: const Text('Repost'),
                  subtitle: const Text('Share this reel instantly'),
                  onTap: () {
                    Navigator.pop(context);
                    _performRepost(reelId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded),
                  title: const Text('Repost with caption'),
                  subtitle: const Text('Add your own text before reposting'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRepostCaptionDialog(reelId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (widget.isActive) {
        _playVideo();
      }
    });
  }

  void _showRepostCaptionDialog(String reelId) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,
          title: const Text('Repost with caption'),
          content: TokenSuggestionField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) {
              final caption = controller.text.trim();
              Navigator.pop(context);
              _performRepost(reelId, content: caption);
            },
            enabled: true,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              hintText: 'Add a caption',
              border: OutlineInputBorder(),
            ),
            suggestionsBuilder: _suggestReelComposerTokens,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final caption = controller.text.trim();
                Navigator.pop(context);
                _performRepost(reelId, content: caption);
              },
              child: const Text('Repost'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _performRepost(String reelId, {String content = ''}) {
    if (!mounted || _isReposted) return;

    setState(() {
      _isReposted = true;
      _localRepostDelta += 1;
    });

    context.read<ReelBloc>().add(
          RepostReel(
            reelId: reelId,
            index: widget.index,
            content: content,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          content.isEmpty ? 'Reel reposted' : 'Reel reposted with caption',
        ),
      ),
    );
  }

  Future<void> _toggleFollow() async {
    if (!mounted || _isFollowBusy) return;

    final nextFollowing = !_isFollowing;

    setState(() {
      _isFollowing = nextFollowing;
      _isFollowBusy = true;
    });

    try {
      try {
        final friendsBloc = context.read<FriendsBloc>();
        if (nextFollowing) {
          friendsBloc.add(FollowUser(userId: _userId));
        } else {
          friendsBloc.add(UnfollowUser(userId: _userId));
        }
      } catch (_) {
        if (nextFollowing) {
          await FriendsService().followUser(_userId);
        } else {
          await FriendsService().unfollowUser(_userId);
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isFollowing = !nextFollowing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFollowBusy = false;
        });
      }
    }
  }

  bool _isCurrentUser() {
    final userId = widget.reel['userId'] ?? _user['id'];

    if (userId is int) return userId == widget.currentUserId;
    if (userId is String) {
      return int.tryParse(userId) == widget.currentUserId;
    }

    return false;
  }

  int get _userId {
    final userId = widget.reel['userId'] ?? _user['id'];

    if (userId is int) return userId;
    if (userId is String) return int.tryParse(userId) ?? 0;
    return 0;
  }

  String? get _reelId {
    final id = widget.reel['id'] ?? widget.reel['_id'];
    final value = id?.toString();

    if (value == null || value.isEmpty) return null;

    return value;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoLayer(),
          _buildGradients(),
          if (!_isPlaying && _isInitialized) _buildPlayPauseOverlay(),
          _buildRightActions(),
          _buildMuteButton(),
          _buildBottomInfo(),
          if (_isInitialized && _videoController != null)
            _VideoProgress(controller: _videoController!),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_hasVideoError || _videoUrl.isEmpty) {
      return const _VideoUnavailable();
    }

    if (!_isInitialized || _videoController == null) {
      return const _VideoLoading();
    }

    final size = _videoController!.value.size;

    if (size.width <= 0 || size.height <= 0) {
      return const _VideoLoading();
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  Widget _buildPlayPauseOverlay() {
    return IgnorePointer(
      child: Container(
        color: AppColors.black.withOpacity(0.18),
        child: Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.45),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.white,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradients() {
    return IgnorePointer(
      child: Column(
        children: [
          Container(
            height: 130,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.black.withOpacity(0.45),
                  AppColors.transparent,
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.black.withOpacity(0.72),
                  AppColors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightActions() {
    final likeCount = _readInt(widget.reel['likes']) + _localLikeDelta;
    final commentCount = _readInt(
          widget.reel['commentCount'] ?? widget.reel['comments'],
        ) +
        _localCommentDelta;
    final shareCount = _readInt(
          widget.reel['shareCount'] ?? widget.reel['shares'],
        ) +
        _localShareDelta;
    final repostCount = _readInt(
          widget.reel['repostCount'] ?? widget.reel['reposts'],
        ) +
        _localRepostDelta;

    return Positioned(
      right: 14,
      bottom: 104,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              icon: _isLiked ? Icons.favorite : Icons.favorite_border,
              label: _formatCount(likeCount < 0 ? 0 : likeCount),
              color: _isLiked ? AppColors.redColor : AppColors.white,
              onTap: _handleLike,
            ),
            const SizedBox(height: 20),
            _ActionButton(
              icon: Icons.mode_comment_outlined,
              label: _formatCount(commentCount < 0 ? 0 : commentCount),
              onTap: _handleComment,
            ),
            const SizedBox(height: 20),
            _ActionButton(
              icon: Icons.send_rounded,
              label: _formatCount(shareCount < 0 ? 0 : shareCount),
              onTap: _handleShare,
            ),
            const SizedBox(height: 20),
            _ActionButton(
              icon:
                  _isReposted ? Icons.repeat_on_rounded : Icons.repeat_rounded,
              label: _formatCount(repostCount < 0 ? 0 : repostCount),
              color: _isReposted ? AppColors.primary : AppColors.white,
              onTap: _handleRepost,
            ),
            const SizedBox(height: 20),
            _ActionButton(
              icon: Icons.more_horiz,
              label: '',
              onTap: () {},
            ),
            const SizedBox(height: 22),
            _AudioAvatar(
              imageUrl: _avatarUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuteButton() {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 74,
      right: 16,
      child: SafeArea(
        child: Material(
          color: AppColors.black.withOpacity(0.34),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _toggleMute,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 42,
              height: 62,
              child: Icon(
                _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: AppColors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    final username = _username;
    final avatar = _avatarUrl;
    final isVerified = _readBool(
      widget.reel['isVerified'] ?? _user['verified'],
    );
    final caption = widget.reel['caption']?.toString() ?? '';
    final hashtags = _readHashtags(widget.reel['hashtags']);
    final audio = widget.reel['audio']?.toString() ??
        widget.reel['music']?.toString() ??
        'Original Sound';
    final audioArtist = widget.reel['audioArtist']?.toString() ??
        _user['name']?.toString() ??
        username;

    return Positioned(
      left: 16,
      right: 88,
      bottom: 24,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ProfileAvatar(
                  imageUrl: avatar,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified,
                    color: AppColors.blue,
                    size: 16,
                  ),
                ],
                if (!_isCurrentUser()) ...[
                  const SizedBox(width: 10),
                  _FollowButton(
                    isFollowing: _isFollowing,
                    onTap: _toggleFollow,
                  ),
                ],
              ],
            ),
            if (caption.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              EffectText(
                text: caption,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  height: 1.25,
                ),
                hashtagColor: AppColors.storyYellow,
                mentionColor: AppColors.secondary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (hashtags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 5,
                runSpacing: 2,
                children: hashtags.map((tag) {
                  return Text(
                    '#$tag',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.music_note,
                  color: AppColors.white,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '$audio · $audioArtist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get _username {
    return widget.reel['username']?.toString() ??
        _user['username']?.toString() ??
        _user['name']?.toString() ??
        'User';
  }

  String get _avatarUrl {
    return widget.reel['userProfile']?.toString() ??
        widget.reel['avatar']?.toString() ??
        _user['avatar']?.toString() ??
        '';
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;

    return 0;
  }

  bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }

    return false;
  }

  List<String> _readHashtags(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().replaceFirst('#', '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((e) => e.replaceFirst('#', '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }

    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }

    return count.toString();
  }
}

class _VideoLoading extends StatelessWidget {
  const _VideoLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _VideoUnavailable extends StatelessWidget {
  const _VideoUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: AppColors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Video unavailable',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.55),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoProgress extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoProgress({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final duration = value.duration.inMilliseconds;
          final position = value.position.inMilliseconds;

          final progress =
              duration <= 0 ? 0.0 : (position / duration).clamp(0.0, 1.0);

          return LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            color: AppColors.white,
            backgroundColor: AppColors.white.withOpacity(0.18),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String imageUrl;

  const _ProfileAvatar({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _fallback();
    }

    if (!imageUrl.startsWith('http')) {
      return _fallback();
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(),
          placeholder: (_, __) => _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.person,
        color: AppColors.white.withOpacity(0.55),
        size: 20,
      ),
    );
  }
}

class _AudioAvatar extends StatelessWidget {
  final String imageUrl;

  const _AudioAvatar({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _fallback();
    }

    if (!imageUrl.startsWith('http')) {
      return _fallback();
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withOpacity(0.35),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(),
          placeholder: (_, __) => _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withOpacity(0.35),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.music_note,
        color: AppColors.white.withOpacity(0.6),
        size: 24,
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;

  const _FollowButton({
    required this.isFollowing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isFollowing
                ? AppColors.white.withOpacity(0.55)
                : AppColors.redColor,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isFollowing ? AppColors.transparent : AppColors.redColor,
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: isFollowing
                ? AppColors.white.withOpacity(0.85)
                : AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ReelCommentsSheet extends StatefulWidget {
  final String reelId;
  final VoidCallback onCommentAdded;

  const _ReelCommentsSheet({
    required this.reelId,
    required this.onCommentAdded,
  });

  @override
  State<_ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<_ReelCommentsSheet> {
  final ReelService _reelService = ReelService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _comments = const [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final comments = await _reelService.getReelComments(widget.reelId);

      if (!mounted) return;

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final comment = await _reelService.addReelComment(
        reelId: widget.reelId,
        data: {
          'content': text,
          'comment': text,
          'text': text,
        },
      );

      if (!mounted) return;

      _controller.clear();
      widget.onCommentAdded();

      setState(() {
        _comments = [
          if (comment.isNotEmpty) comment else {'content': text},
          ..._comments,
        ];
        _isSending = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, sheetController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Comments',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildComments(sheetController),
                ),
                _buildCommentInput(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComments(ScrollController controller) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_error != null) {
      return _SheetMessage(
        icon: Icons.error_outline,
        title: 'Could not load comments',
        subtitle: _error!,
        actionLabel: 'Retry',
        onAction: _loadComments,
      );
    }

    if (_comments.isEmpty) {
      return const _SheetMessage(
        icon: Icons.mode_comment_outlined,
        title: 'No comments yet',
        subtitle: 'Start the conversation.',
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      itemCount: _comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _CommentTile(comment: _comments[index]);
      },
    );
  }

  Widget _buildCommentInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TokenSuggestionField(
                controller: _controller,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (!_isSending) _sendComment();
                },
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
                suggestionsBuilder: _suggestReelComposerTokens,
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _isSending ? null : _sendComment,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.divider,
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_upward,
                      color: AppColors.white,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelShareSheet extends StatefulWidget {
  final Map<String, dynamic> reel;
  final String reelId;
  final VoidCallback onShared;

  const _ReelShareSheet({
    required this.reel,
    required this.reelId,
    required this.onShared,
  });

  @override
  State<_ReelShareSheet> createState() => _ReelShareSheetState();
}

class _ReelShareSheetState extends State<_ReelShareSheet> {
  late final ChatService _chatService;
  final TextEditingController _searchController = TextEditingController();

  int? _sendingToUserId;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => FriendsBloc()..add(const LoadFriends()),
        ),
        BlocProvider(
          create: (_) => ChatBloc()..add(LoadConversations()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.68,
            minChildSize: 0.42,
            maxChildSize: 0.9,
            builder: (context, sheetController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Send to',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.close,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSearchField(),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildFriendsList(context, sheetController),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 14,
        ),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search friends',
          hintStyle: TextStyle(
            color: AppColors.textHint,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.icon,
          ),
          filled: true,
          fillColor: AppColors.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList(
    BuildContext context,
    ScrollController controller,
  ) {
    return BlocBuilder<FriendsBloc, FriendsState>(
      builder: (context, friendsState) {
        if (friendsState.friendsStatus == FriendsStatus.loading &&
            friendsState.friends.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          );
        }

        if (friendsState.friendsStatus == FriendsStatus.error &&
            friendsState.friends.isEmpty) {
          return _SheetMessage(
            icon: Icons.people_outline,
            title: 'Could not load friends',
            subtitle: friendsState.error ?? 'Please try again.',
            actionLabel: 'Retry',
            onAction: () {
              context.read<FriendsBloc>().add(const LoadFriends());
            },
          );
        }

        final friends = _filteredFriends(friendsState.friends);

        if (friends.isEmpty) {
          return const _SheetMessage(
            icon: Icons.people_outline,
            title: 'No friends found',
            subtitle: 'Mutual friends will show up here.',
          );
        }

        return BlocBuilder<ChatBloc, ChatState>(
          builder: (context, chatState) {
            return ListView.separated(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              itemCount: friends.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final friend = friends[index];
                final conversation = _conversationFor(
                  chatState.conversations,
                  friend.id,
                );

                return _ShareFriendTile(
                  friend: friend,
                  isSending: _sendingToUserId == friend.id,
                  onTap: () => _shareToFriend(
                    context: context,
                    friend: friend,
                    conversationId: conversation?.id,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<FriendUser> _filteredFriends(List<FriendUser> friends) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return friends;

    return friends.where((friend) {
      return friend.name.toLowerCase().contains(query) ||
          friend.username.toLowerCase().contains(query);
    }).toList();
  }

  ConversationModel? _conversationFor(
    List<ConversationModel> conversations,
    int userId,
  ) {
    for (final conversation in conversations) {
      if (conversation.userId == userId) return conversation;
    }

    return null;
  }

  Future<void> _shareToFriend({
    required BuildContext context,
    required FriendUser friend,
    required int? conversationId,
  }) async {
    if (_sendingToUserId != null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _sendingToUserId = friend.id;
    });

    try {
      final response = await _chatService.sendMessage(
        receiverId: friend.id,
        message: _shareText,
        messageType: 'reel',
        mediaUrl: _videoUrl,
      );

      if (!mounted) return;

      widget.onShared();

      final resolvedConversationId = _readInt(
        response?['conversationId'] ?? response?['conversation_id'],
      );
      final targetConversationId =
          resolvedConversationId > 0 ? resolvedConversationId : conversationId;

      navigator.pop();

      if (targetConversationId != null && targetConversationId > 0) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => ChatBloc(),
              child: ChatPage(
                conversationId: targetConversationId,
                userName: friend.name,
                userAvatar: friend.avatar ?? '',
                userId: friend.id,
              ),
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Reel sent to ${friend.name}'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingToUserId = null;
        });
      }
    }
  }

  String get _videoUrl {
    final url = widget.reel['videoUrl'] ?? widget.reel['url'];
    return url?.toString() ?? '';
  }

  String get _caption {
    return widget.reel['caption']?.toString().trim() ?? '';
  }

  String get _shareText {
    final buffer = StringBuffer('Shared a reel');

    if (_caption.isNotEmpty) {
      buffer.write(': $_caption');
    }

    if (_videoUrl.isNotEmpty) {
      buffer.write('\n$_videoUrl');
    }

    return buffer.toString();
  }
}

class _CommentTile extends StatelessWidget {
  final dynamic comment;

  const _CommentTile({
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final data = _asMap(comment);
    final user = _asMap(data['user']);
    final name = data['username']?.toString() ??
        user['username']?.toString() ??
        user['name']?.toString() ??
        'User';
    final avatar =
        data['avatar']?.toString() ?? user['avatar']?.toString() ?? '';
    final text = data['content']?.toString() ??
        data['comment']?.toString() ??
        data['text']?.toString() ??
        '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommentAvatar(
          imageUrl: avatar,
          fallback: name,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShareFriendTile extends StatelessWidget {
  final FriendUser friend;
  final bool isSending;
  final VoidCallback onTap;

  const _ShareFriendTile({
    required this.friend,
    required this.isSending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: isSending ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          child: Row(
            children: [
              CommentAvatar(
                imageUrl: friend.avatar ?? '',
                fallback: friend.name,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            friend.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (friend.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: AppColors.blue,
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${friend.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 42,
                height: 34,
                child: isSending
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SheetMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.textHint,
              size: 46,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;

  return 0;
}
