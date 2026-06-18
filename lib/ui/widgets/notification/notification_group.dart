import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/ui/widgets/notification/notification_utils.dart';
import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/ui/widgets/common/effect_text.dart';

class NotificationGroupWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final bool isUnread;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NotificationGroupWidget({
    super.key,
    required this.notification,
    required this.isUnread,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final data = NotificationUtils.asMap(notification['data']);
    final type = notification['type']?.toString() ?? 'general';
    final groupCount = NotificationUtils.readInt(notification['groupCount']);
    final actorName = NotificationUtils.actorName(notification);
    final content = NotificationUtils.getContent(notification);
    final time = NotificationUtils.formatTime(notification['createdAt']);
    final postImage = (notification['postImage'] ?? 
        data['postImage'] ?? 
        data['imageUrl'] ?? ''
    ).toString();
    final avatar = (notification['actorAvatar'] ?? data['actorAvatar'] ?? '').toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? accent.withOpacity(0.35) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(isUnread ? 0.07 : 0.03),
            blurRadius: isUnread ? 18 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(avatar, actorName),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EffectText(
                      text: _buildNotificationText(actorName, type, groupCount, content),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        color: isUnread ? AppColors.secondary : AppColors.text,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w400,
                      ),
                      hashtagColor: AppColors.primary,
                      mentionColor: AppColors.secondary,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.greyColor.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _buildActionLabel(type, groupCount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (postImage.isNotEmpty)
                _postPreview(postImage)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary.withOpacity(0.7),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildNotificationText(String actorName, String type, int groupCount, String content) {
    if (groupCount > 1 && NotificationUtils.shouldGroup(type)) {
      if (type == 'like' || type == 'post_like') {
        return '$actorName liked $groupCount of your posts.';
      }
      return '$actorName $content';
    }
    return '$actorName $content';
  }

  String _buildActionLabel(String type, int groupCount) {
    if (groupCount > 1 && NotificationUtils.shouldGroup(type)) {
      return '$groupCount updates';
    }
    return NotificationUtils.actionLabel(type);
  }

  Widget _buildAvatar(String avatar, String actorName) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnread ? accent.withOpacity(0.45) : AppColors.border,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: avatar.isNotEmpty && avatar.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: avatar,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _avatarFallback(actorName),
                  )
                : _avatarFallback(actorName),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              border: Border.all(color: AppColors.white, width: 2),
            ),
            child: Icon(
              NotificationUtils.iconForType(notification['type']?.toString() ?? 'general'),
              size: 12,
              color: AppColors.white,
            ),
          ),
        ),
        if (isUnread)
          Positioned(
            left: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }


  Widget _postPreview(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        memCacheWidth: 96,
        memCacheHeight: 96,
        errorWidget: (context, error, stackTrace) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.article_outlined,
              color: accent,
              size: 20,
            ),
          );
        },
      ),
    );
  }
}