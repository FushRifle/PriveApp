import 'package:cirqle/data/models/status_model.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cirqle/app/configs/colors.dart';
import 'package:cirqle/app/configs/theme.dart';

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
      name: 'My Status',
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Avatar Container
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _getAvatarGradient(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
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
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$statusCount',
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
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              isAddStatus ? 'Your Story' : name,
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 12,
                fontWeight: hasUnviewed ? FontWeight.w600 : FontWeight.w500,
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
        Colors.grey.withOpacity(0.4),
        Colors.grey.withOpacity(0.2),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildAvatar() {
    final hasValidAvatar = avatar.isNotEmpty && avatar != 'null';

    if (!hasValidAvatar) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            isAddStatus ? Icons.add_a_photo : Icons.person,
            color: Colors.grey[400],
            size: 32,
          ),
        ),
      );
    }

    if (avatar.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: avatar,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: Icon(Icons.person, color: Colors.grey[400], size: 32),
        ),
      );
    }

    return ClipOval(
      child: Image.asset(
        avatar,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: Icon(Icons.person, color: Colors.grey[400], size: 32),
        ),
      ),
    );
  }
}
