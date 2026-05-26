import 'package:clique/data/models/status_model.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';

class StatusWidget extends StatelessWidget {
  final String name;
  final String avatar;
  final VoidCallback onTap;
  final bool isAddStatus;
  final int statusCount;
  final bool hasUnviewed;

  const StatusWidget({
    super.key,
    required this.name,
    required this.avatar,
    required this.onTap,
    this.isAddStatus = false,
    this.statusCount = 0,
    this.hasUnviewed = false,
  });

  factory StatusWidget.fromStoryUser({
    required StoryUser user,
    required VoidCallback onTap,
    int statusCount = 0,
    bool hasUnviewed = false,
  }) {
    return StatusWidget(
      name: user.name,
      avatar: user.avatar,
      onTap: onTap,
      statusCount: statusCount,
      hasUnviewed: hasUnviewed,
      isAddStatus: false,
    );
  }

  factory StatusWidget.addStatus({required VoidCallback onTap}) {
    return StatusWidget(
      name: 'Your Story',
      avatar: '',
      onTap: onTap,
      isAddStatus: true,
      statusCount: 0,
      hasUnviewed: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Avatar Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _getAvatarGradient(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: Container(
                        color: Colors.white,
                        child: _buildAvatar(),
                      ),
                    ),
                  ),
                ),
                // Status Count Badge
                if (!isAddStatus && statusCount > 1)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          statusCount > 9 ? '9+' : '$statusCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Add Story Button
                if (isAddStatus)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Name
            Text(
              isAddStatus ? 'Your Story' : name,
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 11,
                fontWeight: hasUnviewed ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Gradient? _getAvatarGradient() {
    if (isAddStatus) return null;

    if (hasUnviewed) {
      return const LinearGradient(
        colors: [
          Color(0xFF833AB4),
          Color(0xFFFD1D1D),
          Color(0xFFFCAF45),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return LinearGradient(
      colors: [
        Colors.grey.withOpacity(0.3),
        Colors.grey.withOpacity(0.1),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildAvatar() {
    final hasValidAvatar = avatar.isNotEmpty && avatar != 'null';

    if (!hasValidAvatar) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Icon(
            isAddStatus ? Icons.add_a_photo : Icons.person,
            color: Colors.grey[400],
            size: 28,
          ),
        ),
      );
    }

    if (avatar.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: avatar,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[100],
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[100],
          child: Icon(Icons.person, color: Colors.grey[400], size: 28),
        ),
      );
    }

    return ClipOval(
      child: Image.asset(
        avatar,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[100],
          child: Icon(Icons.person, color: Colors.grey[400], size: 28),
        ),
      ),
    );
  }
}
