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
  final Widget? trailing;

  const NotificationGroupWidget({
    super.key,
    required this.notification,
    required this.isUnread,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
    this.trailing,
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
            data['imageUrl'] ??
            '')
        .toString();
    final avatar =
        (notification['actorAvatar'] ?? data['actorAvatar'] ?? '').toString();
    final showTrailing = trailing != null;

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
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(avatar, actorName),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EffectText(
                          text: _buildNotificationText(
                              actorName, type, groupCount, content),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: isUnread
                                ? AppColors.secondary
                                : AppColors.text,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w400,
                          ),
                          hashtagColor: AppColors.primary,
                          mentionColor: AppColors.secondary,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 5),
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
                              width: 3,
                              height: 3,
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
                  if (!showTrailing) ...[
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
                ],
              ),
              if (showTrailing) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const SizedBox(width: 66), // Align with text content
                    if (postImage.isNotEmpty) ...[
                      _postPreview(postImage),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: trailing!,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _buildNotificationText(
      String actorName, String type, int groupCount, String content) {
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
            boxShadow: [
              if (isUnread)
                BoxShadow(
                  color: accent.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ClipOval(
            child: avatar.isNotEmpty && avatar.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: avatar,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _avatarFallback(actorName),
                    placeholder: (_, __) => Container(
                      color: AppColors.primary.withOpacity(0.05),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                    ),
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
              border: Border.all(color: AppColors.card, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              NotificationUtils.iconForType(
                  notification['type']?.toString() ?? 'general'),
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
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.card, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _postPreview(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.border.withOpacity(0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          memCacheWidth: 96,
          memCacheHeight: 96,
          errorWidget: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.image_outlined,
                color: accent.withOpacity(0.5),
                size: 20,
              ),
            );
          },
          placeholder: (_, __) => Container(
            color: accent.withOpacity(0.05),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}