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
    return Material(
      color: AppColors.transparent,
      child: SizedBox(
        width: 72,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _getAvatarGradient(),
                        border: isAddStatus
                            ? Border.all(
                                color: AppColors.cardBorderColor,
                                width: 1.2,
                              )
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: Container(
                            color: AppColors.cardColor,
                            child: _buildAvatar(),
                          ),
                        ),
                      ),
                    ),
                    if (!isAddStatus && statusCount > 1)
                      Positioned(
                        bottom: 0,
                        right: 1,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cardColor,
                              width: 1.6,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              statusCount > 9 ? '9+' : '$statusCount',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (isAddStatus)
                      Positioned(
                        bottom: 0,
                        right: 1,
                        child: Container(
                          width: 21,
                          height: 21,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cardColor,
                              width: 1.6,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: AppColors.white,
                            size: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  isAddStatus ? 'Your Story' : name,
                  style: AppTheme.blackTextStyle.copyWith(
                    fontSize: 11,
                    fontWeight: hasUnviewed ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Gradient? _getAvatarGradient() {
    if (isAddStatus) return null;

    if (hasUnviewed) {
      return const LinearGradient(
        colors: [
          AppColors.storyRingPurple,
          AppColors.storyRingRed,
          AppColors.storyRingOrange,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return LinearGradient(
      colors: [
        AppColors.grey.withOpacity(0.3),
        AppColors.grey.withOpacity(0.1),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildAvatar() {
    final hasValidAvatar = avatar.isNotEmpty && avatar != 'null';

    if (!hasValidAvatar) {
      return Container(
        color: AppColors.backgroundColor,
        child: Center(
          child: Icon(
            isAddStatus ? Icons.add_a_photo : Icons.person,
            color: AppColors.textSecondary,
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
          color: AppColors.backgroundColor,
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
          color: AppColors.backgroundColor,
          child: Icon(Icons.person, color: AppColors.textSecondary, size: 28),
        ),
      );
    }

    return ClipOval(
      child: Image.asset(
        avatar,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.backgroundColor,
          child: Icon(Icons.person, color: AppColors.textSecondary, size: 28),
        ),
      ),
    );
  }
}
