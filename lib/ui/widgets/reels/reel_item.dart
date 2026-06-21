import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/friends/friends_bloc.dart';
import 'package:clique/bloc/reels/reel_bloc.dart';
import 'package:clique/core/services/friends/friends_service.dart';
import 'package:clique/core/services/reel/reel_service.dart';

import 'package:clique/ui/widgets/common/token_suggestion_field.dart';
import 'package:clique/ui/widgets/common/effect_text.dart';
import 'package:clique/ui/widgets/reels/helpers/reel_helpers.dart';
import 'package:clique/ui/widgets/reels/helpers/reel_suggestions.dart';
import 'package:clique/ui/widgets/reels/reel_actions.dart';
import 'package:clique/ui/widgets/reels/reel_comments.dart';
import 'package:clique/ui/widgets/reels/reel_share.dart';
import 'package:clique/ui/widgets/reels/reel_video.dart';

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
    _refreshRelationship();
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
    _isLiked = readBool(widget.reel['isLiked']);
    _isReposted = readBool(
      widget.reel['isReposted'] ?? widget.reel['is_reposted'],
    );
    _isFollowing = readBool(
      widget.reel['isFollowing'] ?? _user['isFollowing'],
    );

    _localLikeDelta = 0;
    _localCommentDelta = 0;
    _localShareDelta = 0;
    _localRepostDelta = 0;
  }

  Future<void> _refreshRelationship() async {
    if (_isCurrentUser() || _userId <= 0) return;

    try {
      final relationship = await FriendsService().checkRelationship(_userId);
      if (!mounted) return;
      setState(() {
        _isFollowing = relationship.isFollowing;
      });
    } catch (_) {
      // Keep the server-provided reel flag when relationship lookup is unavailable.
    }
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
        return ReelCommentsSheet(
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
        return ReelShareSheet(
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
        SnackBar(
          content: Text(
            'Already reposted',
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.card,
        ),
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
            suggestionsBuilder: suggestReelComposerTokens,
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
          style: TextStyle(color: AppColors.text),
        ),
        backgroundColor: AppColors.card,
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
      if (nextFollowing) {
        await FriendsService().followUser(_userId);
      } else {
        await FriendsService().unfollowUser(_userId);
      }
      if (!mounted) return;
      try {
        context.read<FriendsBloc>().add(LoadFollowStats());
      } catch (_) {}
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().toLowerCase();
      if (nextFollowing &&
          (message.contains('already') ||
              message.contains('exists') ||
              message.contains('following'))) {
        setState(() => _isFollowing = true);
        return;
      }
      setState(() {
        _isFollowing = !nextFollowing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
            style: TextStyle(color: AppColors.text),
          ),
          backgroundColor: AppColors.card,
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

  Future<void> _showMoreActions() async {
    _pauseVideo();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final isOwner = _isCurrentUser();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                if (isOwner)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: const Text('Delete'),
                    textColor: AppColors.redColor,
                    iconColor: AppColors.redColor,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteReel();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.bookmark_border_rounded),
                  title: const Text('Save'),
                  onTap: () {
                    Navigator.pop(context);
                    _saveReel();
                  },
                ),
                if (!isOwner)
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Report'),
                    onTap: () {
                      Navigator.pop(context);
                      _reportReel();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (widget.isActive) {
      _playVideo();
    }
  }

  Future<void> _saveReel() async {
    final reelId = _reelId;
    if (reelId == null) return;
    try {
      await ReelService().saveReel(reelId);
      if (!mounted) return;
      _showSnackBar('Reel saved');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _reportReel() async {
    final reelId = _reelId;
    if (reelId == null) return;
    try {
      await ReelService().reportReel(reelId);
      if (!mounted) return;
      _showSnackBar('Report submitted');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _deleteReel() async {
    final reelId = _reelId;
    if (reelId == null) return;
    try {
      await ReelService().deleteReel(reelId);
      if (!mounted) return;
      _showSnackBar('Reel deleted');
      context.read<ReelBloc>().add(RefreshReels());
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: AppColors.text),
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            VideoProgress(controller: _videoController!),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_hasVideoError || _videoUrl.isEmpty) {
      return const VideoUnavailable();
    }

    if (!_isInitialized || _videoController == null) {
      return const VideoLoading();
    }

    final size = _videoController!.value.size;

    if (size.width <= 0 || size.height <= 0) {
      return const VideoLoading();
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
    final likeCount = readInt(widget.reel['likes']) + _localLikeDelta;
    final commentCount = readInt(
          widget.reel['commentCount'] ?? widget.reel['comments'],
        ) +
        _localCommentDelta;
    final shareCount = readInt(
          widget.reel['shareCount'] ?? widget.reel['shares'],
        ) +
        _localShareDelta;
    final repostCount = readInt(
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
            ActionButton(
              icon: _isLiked ? Icons.favorite : Icons.favorite_border,
              label: formatCount(likeCount < 0 ? 0 : likeCount),
              color: _isLiked ? AppColors.redColor : AppColors.white,
              onTap: _handleLike,
            ),
            const SizedBox(height: 20),
            ActionButton(
              icon: Icons.mode_comment_outlined,
              label: formatCount(commentCount < 0 ? 0 : commentCount),
              onTap: _handleComment,
            ),
            const SizedBox(height: 20),
            ActionButton(
              icon: Icons.send_rounded,
              label: formatCount(shareCount < 0 ? 0 : shareCount),
              onTap: _handleShare,
            ),
            const SizedBox(height: 20),
            ActionButton(
              icon:
                  _isReposted ? Icons.repeat_on_rounded : Icons.repeat_rounded,
              label: formatCount(repostCount < 0 ? 0 : repostCount),
              color: _isReposted ? AppColors.primary : AppColors.white,
              onTap: _handleRepost,
            ),
            const SizedBox(height: 20),
            ActionButton(
              icon: Icons.more_horiz,
              label: '',
              onTap: _showMoreActions,
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
    final isVerified = readBool(
      widget.reel['isVerified'] ?? _user['verified'],
    );
    final caption = widget.reel['caption']?.toString() ?? '';
    final hashtags = readHashtags(widget.reel['hashtags']);
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
                ProfileAvatar(
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
                  FollowButton(
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
}