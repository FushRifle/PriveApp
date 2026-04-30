import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/app/configs/colors.dart';
import 'package:social_media_app/app/configs/theme.dart';
import '../../widgets/home/custom_app_bar.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildCustomAppBar(context),
            const SizedBox(height: 18),
            _buildMessageList(),
            // Add bottom padding to account for bottom nav bar
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackColor.withOpacity(0.2),
                  blurRadius: 35,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/ic_logo.png',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "Messages",
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
              // TODO: Navigate to search
            },
            child: Image.asset(
              "assets/images/ic_search.png",
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              print('New message tapped');
              // TODO: Create new message
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.purpleColor.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.edit,
                size: 20,
                color: AppColors.purpleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final messages = [
      {
        'name': 'Sarah Johnson',
        'message': 'Hey! How are you doing?',
        'time': '2m ago',
        'avatar': 'assets/images/img_profile.jpeg',
        'unread': true,
        'online': true,
      },
      {
        'name': 'Michael Chen',
        'message': 'Did you see the new post?',
        'time': '1h ago',
        'avatar': 'assets/images/img_profile.jpeg',
        'unread': true,
        'online': false,
      },
      {
        'name': 'Emma Wilson',
        'message': 'Thanks for the follow back! 🙌',
        'time': '3h ago',
        'avatar': 'assets/images/img_profile.jpeg',
        'unread': false,
        'online': true,
      },
      {
        'name': 'James Rodriguez',
        'message': 'Great content! Keep it up 🔥',
        'time': 'Yesterday',
        'avatar': 'assets/images/img_profile.jpeg',
        'unread': false,
        'online': false,
      },
      {
        'name': 'Lisa Kim',
        'message': 'When is the next event?',
        'time': 'Yesterday',
        'avatar': 'assets/images/img_profile.jpeg',
        'unread': false,
        'online': false,
      },
      {
        'name': 'David Brown',
        'message': 'Check out my latest post!',
        'time': '2d ago',
        'avatar': 'assets/images/img_profile.jpeg',
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
    required String name,
    required String message,
    required String time,
    required String avatar,
    required bool isUnread,
    required bool isOnline,
  }) {
    return GestureDetector(
      onTap: () {
        print('Open chat with: $name');
        // TODO: Navigate to chat screen
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
