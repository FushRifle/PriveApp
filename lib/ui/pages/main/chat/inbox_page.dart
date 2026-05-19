import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cirqle/app/configs/colors.dart';
import 'package:cirqle/app/configs/theme.dart';
import 'package:cirqle/ui/pages/main/chat/chat_page.dart';
import '../../../widgets/home/custom_app_bar.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            const SizedBox(height: 8),
            Expanded(
              child: _buildMessageList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return CustomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Text(
              "Chats",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // TODO: Navigate to search
                debugPrint('Search tapped');
              },
              icon: const Icon(
                Icons.search,
                color: AppColors.primary,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    final messages = [
      _ChatMessage(
        id: '1',
        name: 'Sarah Johnson',
        message: 'Hey! How are you doing?',
        time: '2m ago',
        avatar: '',
        isUnread: true,
        isOnline: true,
        unreadCount: 2,
      ),
      _ChatMessage(
        id: '2',
        name: 'Michael Chen',
        message: 'Did you see the new post?',
        time: '1h ago',
        avatar: '',
        isUnread: true,
        isOnline: false,
        unreadCount: 1,
      ),
      _ChatMessage(
        id: '3',
        name: 'Emma Wilson',
        message: 'Thanks for the follow back! 🙌',
        time: '3h ago',
        avatar: '',
        isUnread: false,
        isOnline: true,
        unreadCount: 0,
      ),
      _ChatMessage(
        id: '4',
        name: 'James Rodriguez',
        message: 'Great content! Keep it up 🔥',
        time: 'Yesterday',
        avatar: '',
        isUnread: false,
        isOnline: false,
        unreadCount: 0,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageItem(context, message);
      },
    );
  }

  Widget _buildMessageItem(BuildContext context, _ChatMessage message) {
    final firstLetter =
        message.name.isNotEmpty ? message.name[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              userName: message.name,
              userAvatar: message.avatar,
              userId: message.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUnread
              ? AppColors.primary.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: message.isUnread
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.15),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: message.isUnread
                          ? AppColors.primary
                          : AppColors.greyColor.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blackColor.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: message.avatar.isNotEmpty
                        ? (message.avatar.startsWith('http')
                            ? Image.network(
                                message.avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarFallback(firstLetter),
                              )
                            : Image.asset(
                                message.avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarFallback(firstLetter),
                              ))
                        : _avatarFallback(firstLetter),
                  ),
                ),
                if (message.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.greenColor,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.name,
                          style: AppTheme.blackTextStyle.copyWith(
                            fontWeight: message.isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        message.time,
                        style: AppTheme.blackTextStyle.copyWith(
                          fontSize: 11,
                          color: message.isUnread
                              ? AppColors.primary
                              : AppColors.greyColor,
                          fontWeight: message.isUnread
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.message,
                          style: AppTheme.blackTextStyle.copyWith(
                            fontWeight: message.isUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                            fontSize: 14,
                            color: message.isUnread
                                ? AppColors.blackColor
                                : AppColors.greyColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (message.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.primary,
                          ),
                          child: Text(
                            '${message.unreadCount}',
                            style: AppTheme.whiteTextStyle.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String text) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String id;
  final String name;
  final String message;
  final String time;
  final String avatar;
  final bool isUnread;
  final bool isOnline;
  final int unreadCount;

  _ChatMessage({
    required this.id,
    required this.name,
    required this.message,
    required this.time,
    required this.avatar,
    required this.isUnread,
    required this.isOnline,
    this.unreadCount = 0,
  });
}
