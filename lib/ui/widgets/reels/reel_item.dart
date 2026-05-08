import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/data/models/reel_model.dart';

class ReelItem extends StatefulWidget {
  final ReelModel reel;
  final VoidCallback onNextReel;
  final bool isActive;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final int currentUserId;

  const ReelItem({
    super.key,
    required this.reel,
    required this.onNextReel,
    this.isActive = true,
    this.onLike,
    this.onShare,
    required this.currentUserId,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  late VideoPlayerController _videoController;
  bool _isPlaying = true;
  bool _isInitialized = false;
  bool _isLiked = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.reel.isLiked;
    _initVideoPlayer();
  }

  @override
  void didUpdateWidget(ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _playVideo();
      } else {
        _pauseVideo();
      }
    }
  }

  void _initVideoPlayer() {
    if (widget.reel.videoUrl.isEmpty) {
      _isInitialized = false;
      return;
    }

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.reel.videoUrl),
    );

    _videoController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _videoController.setLooping(true);
    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isActive) {
          _videoController.play();
          _isPlaying = true;
        }
      }
    }).catchError((error) {
      debugPrint('Error initializing video: $error');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    });
  }

  void _playVideo() {
    if (_isInitialized && !_isPlaying) {
      _videoController.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _pauseVideo() {
    if (_isInitialized && _isPlaying) {
      _videoController.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
    widget.onLike?.call();
  }

  void _handleShare() {
    widget.onShare?.call();
  }

  bool _isCurrentUser() {
    return widget.reel.userId == widget.currentUserId;
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          _buildVideoPlayer(),

          // Play/Pause Overlay
          if (!_isPlaying && _isInitialized) _buildPlayPauseOverlay(),

          // Gradients
          _buildGradients(),

          // Right Actions
          _buildRightActions(),

          // Bottom Info
          _buildBottomInfo(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (widget.reel.videoUrl.isEmpty || !_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Video unavailable',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController.value.size.width,
          height: _videoController.value.size.height,
          child: VideoPlayer(_videoController),
        ),
      ),
    );
  }

  Widget _buildPlayPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildGradients() {
    return Column(
      children: [
        // Top gradient
        Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const Spacer(),
        // Bottom gradient
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightActions() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        children: [
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(widget.reel.likeCount),
            onTap: _handleLike,
            color: _isLiked ? AppColors.redColor : Colors.white,
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.comment,
            label: _formatCount(widget.reel.commentCount),
            onTap: () {
              // TODO: Open comments
            },
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.send,
            label: _formatCount(widget.reel.shareCount),
            onTap: _handleShare,
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.more_horiz,
            label: '',
            onTap: () {
              // TODO: More options
            },
          ),
          const SizedBox(height: 20),
          _buildAudioIcon(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        image: widget.reel.userProfile.isNotEmpty
            ? (widget.reel.userProfile.startsWith('http')
                ? DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(widget.reel.userProfile),
                  )
                : DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(widget.reel.userProfile),
                  ))
            : null,
      ),
      child: widget.reel.userProfile.isEmpty
          ? Center(
              child: Icon(
                Icons.music_note,
                color: Colors.white.withOpacity(0.5),
                size: 24,
              ),
            )
          : null,
    );
  }

  Widget _buildBottomInfo() {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to profile
                },
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        image: widget.reel.userProfile.isNotEmpty
                            ? (widget.reel.userProfile.startsWith('http')
                                ? DecorationImage(
                                    fit: BoxFit.cover,
                                    image:
                                        NetworkImage(widget.reel.userProfile),
                                  )
                                : DecorationImage(
                                    fit: BoxFit.cover,
                                    image: AssetImage(widget.reel.userProfile),
                                  ))
                            : null,
                      ),
                      child: widget.reel.userProfile.isEmpty
                          ? Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white.withOpacity(0.5),
                                size: 20,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.reel.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.reel.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
              // Only show follow button if this is NOT the current user's reel
              if (!_isCurrentUser()) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFollowing = !_isFollowing;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isFollowing
                            ? Colors.white.withOpacity(0.5)
                            : AppColors.redColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: _isFollowing
                          ? Colors.transparent
                          : AppColors.redColor,
                    ),
                    child: Text(
                      _isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: _isFollowing
                            ? Colors.white.withOpacity(0.8)
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Caption
          if (widget.reel.caption.isNotEmpty)
            Text(
              widget.reel.caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          // Hashtags
          if (widget.reel.hashtags.isNotEmpty)
            Wrap(
              spacing: 4,
              children: widget.reel.hashtags
                  .map((tag) => Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 12),
          // Audio
          Row(
            children: [
              const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${widget.reel.audio} · ${widget.reel.audioArtist}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
