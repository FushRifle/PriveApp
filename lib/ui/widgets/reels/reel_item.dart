import 'package:flutter/material.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/data/models/reel_model.dart';

class ReelItem extends StatefulWidget {
  final ReelModel reel;
  final VoidCallback onNextReel;
  final bool isActive;

  const ReelItem({
    super.key,
    required this.reel,
    required this.onNextReel,
    this.isActive = true,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  bool _isLiked = false;
  final bool _isMuted = false;
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video placeholder (replace with actual video player)
        _buildVideoPlaceholder(),
        // Gradient overlays
        _buildGradients(),
        // Right side actions
        _buildRightActions(),
        // Bottom info
        _buildBottomInfo(),
        // Top header
      ],
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Icon(
          Icons.play_circle_fill,
          size: 64,
          color: Colors.white.withOpacity(0.5),
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
            label: widget.reel.like,
            onTap: () {
              setState(() {
                _isLiked = !_isLiked;
              });
            },
            color: _isLiked ? AppColors.redColor : Colors.white,
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.comment,
            label: widget.reel.comment,
            onTap: () {
              // TODO: Open comments
            },
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.send,
            label: widget.reel.share,
            onTap: () {
              // TODO: Share
            },
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
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage(widget.reel.userProfile),
        ),
      ),
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
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: AssetImage(widget.reel.userProfile),
                        ),
                      ),
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
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isFollowing = !_isFollowing;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isFollowing
                          ? Colors.white.withOpacity(0.5)
                          : AppColors.redColor,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    color:
                        _isFollowing ? Colors.transparent : AppColors.redColor,
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
          ),
          const SizedBox(height: 12),
          // Caption
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
}
