import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import 'package:social_media_app/ui/pages/main/chat/chat_page.dart';
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildCustomAppBar(context),
            const SizedBox(height: 18),
            _buildMessageList(context),
            const SizedBox(height: 130),
          ],
        ),
      ),
    );
  }

  CustomAppBar _buildCustomAppBar(BuildContext context) {
    return CustomAppBar(
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Text(
            "Chat",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              print('Search tapped');
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search,
                color: AppColors.purpleColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    final messages = [
      {
        'name': 'Sarah Johnson',
        'message': 'Hey! How are you doing?',
        'time': '2m ago',
        'avatar': 'profiles/profile_1.jpeg',
        'unread': true,
        'online': true,
      },
      {
        'name': 'Michael Chen',
        'message': 'Did you see the new post?',
        'time': '1h ago',
        'avatar': 'profiles/profile_2.jpeg',
        'unread': true,
        'online': false,
      },
      {
        'name': 'Emma Wilson',
        'message': 'Thanks for the follow back! 🙌',
        'time': '3h ago',
        'avatar': 'profiles/profile_3.jpeg',
        'unread': false,
        'online': true,
      },
      {
        'name': 'James Rodriguez',
        'message': 'Great content! Keep it up 🔥',
        'time': 'Yesterday',
        'avatar': 'profiles/profile_4.jpeg',
        'unread': false,
        'online': false,
      },
      {
        'name': 'David Brown',
        'message': 'Check out my latest post!',
        'time': '2d ago',
        'avatar': 'assets/images/profile_1.jpeg',
        'unread': false,
        'online': true,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageItem(
          context: context,
          name: message['name']! as String,
          message: message['message']! as String,
          time: message['time']! as String,
          avatar: message['avatar']! as String,
          isUnread: message['unread'] as bool,
          isOnline: message['online'] as bool,
        );
      },
    );
  }

  Widget _buildMessageItem({
    required BuildContext context,
    required String name,
    required String message,
    required String time,
    required String avatar,
    required bool isUnread,
    required bool isOnline,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              userName: name,
              userAvatar: avatar,
              userId: name.toLowerCase().replaceAll(' ', '_'),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.purpleColor.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isUnread
              ? Border.all(
                  color: AppColors.purpleColor.withOpacity(0.1),
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
                      color: isUnread
                          ? AppColors.purpleColor
                          : AppColors.greyColor.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blackColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage(avatar),
                    ),
                  ),
                ),
                if (isOnline)
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
                          color: AppColors.whiteColor,
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
                          name,
                          style: AppTheme.blackTextStyle.copyWith(
                            fontWeight:
                                isUnread ? AppTheme.bold : AppTheme.medium,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: AppTheme.blackTextStyle.copyWith(
                          fontSize: 11,
                          color: isUnread
                              ? AppColors.purpleColor
                              : AppColors.greyColor,
                          fontWeight:
                              isUnread ? AppTheme.medium : AppTheme.regular,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: AppTheme.blackTextStyle.copyWith(
                            fontWeight:
                                isUnread ? AppTheme.medium : AppTheme.regular,
                            fontSize: 14,
                            color: isUnread
                                ? AppColors.blackColor
                                : AppColors.greyColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.purpleColor,
                          ),
                          child: Center(
                            child: Text(
                              '1',
                              style: AppTheme.whiteTextStyle.copyWith(
                                fontSize: 12,
                                fontWeight: AppTheme.bold,
                              ),
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
}
