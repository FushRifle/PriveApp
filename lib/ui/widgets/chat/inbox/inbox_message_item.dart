import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/app/configs/theme.dart';
import 'package:clique/ui/pages/main/chat/inbox_page.dart';
import 'package:clique/ui/widgets/common/app_network_image.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: message.isUnread
                ? AppColors.secondary.withOpacity(0.045)
                : AppColors.transparent,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withOpacity(0.38),
              ),
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: message.isUnread
                            ? AppColors.secondary.withOpacity(0.6)
                            : AppColors.border.withOpacity(0.45),
                        width: 1.5,
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
              const SizedBox(width: 11),

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
                                        ? AppTheme.bold
                                        : AppTheme.semiBold,
                                    fontSize: 13.5,
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
                                    color: AppColors.secondary,
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
                                  color: AppColors.secondary,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          message.time,
                          style: AppTheme.greyTextStyle.copyWith(
                            fontSize: 11,
                            fontWeight: AppTheme.medium,
                            color: message.isUnread
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
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
                            style: AppTheme.greyTextStyle.copyWith(
                              fontSize: 12,
                              height: 1.3,
                              color: message.isTyping
                                  ? AppColors.secondary
                                  : message.isUnread
                                      ? AppColors.text
                                      : AppColors.textSecondary,
                              fontWeight: message.isTyping || message.isUnread
                                  ? AppTheme.semiBold
                                  : AppTheme.regular,
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
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              message.unreadCount > 99
                                  ? '99+'
                                  : '${message.unreadCount}',
                              style: AppTheme.whiteTextStyle.copyWith(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: AppTheme.bold,
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
      return ColoredBox(
        color: AppColors.card,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Image.asset(
            'assets/icons/clique-new.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _avatarFallback('C'),
          ),
        ),
      );
    }

    if (message.avatar.isNotEmpty && message.avatar.startsWith('http')) {
      return AppNetworkImage(
        imageUrl: message.avatar,
        fit: BoxFit.cover,
        preset: AppNetworkImagePreset.avatar,
        errorBuilder: (_) => _avatarFallback(firstLetter),
        placeholder: (_) => Container(
          color: AppColors.primary.withOpacity(0.05),
        ),
      );
    }

    return _avatarFallback(firstLetter);
  }

  Widget _avatarFallback(String text) {
    return Container(
      color: AppColors.secondary.withOpacity(0.1),
      child: Center(
        child: Text(
          text,
          style: AppTheme.blackTextStyle.copyWith(
            fontSize: 17,
            fontWeight: AppTheme.bold,
            color: AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
