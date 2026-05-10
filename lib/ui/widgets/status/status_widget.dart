import 'package:flutter/material.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';
import 'package:Prive/data/models/feeds_models.dart';

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

  // Convenience factory to create from StoryUser
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

  // Convenience factory for add status button
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
      child: Container(
        width: 74,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isAddStatus
                        ? null
                        : (hasUnviewed)
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF833AB4),
                                  Color(0xFFFD1D1D),
                                  Color(0xFFFCAF45),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey.withOpacity(0.5),
                                  Colors.grey.withOpacity(0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: _buildAvatar(),
                    ),
                  ),
                ),

                // Status count badge
                if (!isAddStatus && statusCount > 1)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$statusCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Add story icon for "My Status"
                if (isAddStatus)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
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
            const SizedBox(height: 6),
            Text(
              isAddStatus ? 'My Status' : name,
              style: AppTheme.blackTextStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
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

  Widget _buildAvatar() {
    if (isAddStatus) {
      // For "My Status", show a placeholder or the user's avatar if available
      if (avatar.isEmpty) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.person,
            color: Colors.grey,
            size: 32,
          ),
        );
      }
    }

    if (avatar.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.person,
          color: Colors.grey,
          size: 32,
        ),
      );
    }

    if (avatar.startsWith('http')) {
      return Image.network(
        avatar,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.person,
            color: Colors.grey,
            size: 32,
          ),
        ),
      );
    }

    return Image.asset(
      avatar,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.person,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }
}
