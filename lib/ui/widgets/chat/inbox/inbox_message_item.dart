import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/ui/pages/main/chat/inbox_page.dart';

class InboxMessageItem extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onPin;
  final VoidCallback onMute;
  final VoidCallback onMarkUnread;
  final VoidCallback onArchive;
  final bool isArchived;

  const InboxMessageItem({
    super.key,
    required this.message,
    required this.onTap,
    required this.onLongPress,
    required this.onPin,
    required this.onMute,
    required this.onMarkUnread,
    required this.onArchive,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context) {
    final firstLetter =
        message.name.isNotEmpty ? message.name[0].toUpperCase() : 'U';
    final isBot = message.name.toLowerCase() == 'clique';

    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onPin();
          return false;
        }
        onArchive();
        return true;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 28),
        color: AppColors.secondary,
        child: Icon(
          message.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          color: AppColors.white,
          size: 22,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        color: AppColors.primary,
        child: Icon(
          isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
          color: AppColors.white,
          size: 22,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.cardBorder,
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: message.isUnread
                            ? AppColors.primary.withOpacity(0.25)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: _buildAvatar(firstLetter),
                    ),
                  ),
                  if (message.isOnline)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.greenColor,
                          border: Border.all(
                            color: AppColors.backgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  message.name,
                                  style: AppTheme.blackTextStyle.copyWith(
                                    fontWeight: message.isUnread
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isBot) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 10,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                              if (message.isPinned) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.push_pin_rounded,
                                  size: 12,
                                  color: AppColors.primary.withOpacity(0.6),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          message.time,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: message.isUnread
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (message.isMuted)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.notifications_off_rounded,
                              size: 12,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            message.isTyping ? 'typing...' : message.message,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.3,
                              color: message.isTyping
                                  ? AppColors.primary
                                  : message.isUnread
                                      ? AppColors.text
                                      : AppColors.textSecondary,
                              fontWeight: message.isTyping || message.isUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (message.unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              message.unreadCount > 99
                                  ? '99+'
                                  : '${message.unreadCount}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String firstLetter) {
    if (message.name.toLowerCase() == 'clique') {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text(
            'C',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
        ),
      );
    }

    if (message.avatar.isNotEmpty && message.avatar.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: message.avatar,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _avatarFallback(firstLetter),
        placeholder: (_, __) => Container(
          color: AppColors.primary.withOpacity(0.05),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
        ),
      );
    }

    return _avatarFallback(firstLetter);
  }

  Widget _avatarFallback(String text) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
