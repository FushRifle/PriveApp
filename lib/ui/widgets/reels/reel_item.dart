import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:video_player/video_player.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/reels/reel_bloc.dart';

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
  bool _isLiked = false;

  int _localLikeDelta = 0;
  int _localShareDelta = 0;

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
    _isFollowing = _readBool(
      widget.reel['isFollowing'] ?? _user['isFollowing'],
    );

    _localLikeDelta = 0;
    _localShareDelta = 0;
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
      await controller.setVolume(1);

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

  void _handleShare() {
    final reelId = widget.reel['id']?.toString();

    if (reelId == null || reelId.isEmpty) return;

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
  }

  void _toggleFollow() {
    if (!mounted) return;

    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  bool _isCurrentUser() {
    final userId = widget.reel['userId'] ?? _user['id'];

    if (userId is int) return userId == widget.currentUserId;
    if (userId is String) {
      return int.tryParse(userId) == widget.currentUserId;
    }

    return false;
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
    );
    final shareCount = _readInt(
          widget.reel['shareCount'] ?? widget.reel['shares'],
        ) +
        _localShareDelta;

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
              label: _formatCount(commentCount),
              onTap: () {},
            ),
            const SizedBox(height: 20),
            _ActionButton(
              icon: Icons.send_rounded,
              label: _formatCount(shareCount < 0 ? 0 : shareCount),
              onTap: _handleShare,
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
              Text(
                caption,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  height: 1.25,
                ),
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
