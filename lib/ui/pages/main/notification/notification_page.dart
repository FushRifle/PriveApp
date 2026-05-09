import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Prive/app/configs/colors.dart';
import 'package:Prive/app/configs/theme.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 1,
      'name': 'Sarah Johnson',
      'avatar': 'profiles/profile_1.jpeg',
      'content': 'commented: "This is absolutely stunning! 😍"',
      'time': '2m ago',
      'isUnread': true,
      'postImage': 'profiles/profile_1.jpeg',
    },
    {
      'type': 2,
      'name': 'Michael Chen',
      'avatar': 'profiles/profile_2.jpeg',
      'content': 'started following you.',
      'time': '15m ago',
      'isUnread': true,
    },
    {
      'type': 0,
      'name': 'Emma Wilson',
      'avatar': 'profiles/profile_3.jpeg',
      'content': 'liked your recent photo.',
      'time': '1h ago',
      'isUnread': false,
      'postImage': 'profiles/profile_3.jpeg',
    },
    {
      'type': 3,
      'name': 'James Rodriguez',
      'avatar': 'profiles/profile_4.jpeg',
      'content': 'mentioned you in a comment.',
      'time': '3h ago',
      'isUnread': false,
    },
    {
      'type': 0,
      'name': 'Lisa Kim',
      'avatar': 'profiles/profile_1.jpeg',
      'content': 'liked your story.',
      'time': '5h ago',
      'isUnread': false,
    },
    {
      'type': 1,
      'name': 'David Brown',
      'avatar': 'assets/profiles/profile_2.jpeg',
      'content': 'commented: "This is goals! 🙌"',
      'time': '8h ago',
      'isUnread': false,
      'postImage': 'assets/profiles/profile_2.jpeg',
    },
  ];

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Notifications',
          style: AppTheme.blackTextStyle.copyWith(
            fontWeight: AppTheme.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.black87),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                for (var notification in _notifications) {
                  notification['isUnread'] = false;
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: _notifications.length + 1, // +1 for section header
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildNewestHeader();
              }
              return _buildNotificationItem(_notifications[index - 1]);
            },
          ),
          _buildBlurBottomGradient(),
        ],
      ),
    );
  }

  Widget _buildNewestHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        'NEWEST',
        style: AppTheme.greyTextStyle.copyWith(
          fontSize: 11,
          fontWeight: AppTheme.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item) {
    final bool isUnread = item['isUnread'] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ]
            : [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            item['isUnread'] = false;
          });
          // TODO: Navigate to relevant screen based on type
        },
        child: Row(
          children: [
            // Avatar with Status Indicator
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnread
                          ? AppColors.purpleColor.withOpacity(0.3)
                          : Colors.transparent,
                      width: 2,
                    ),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage(item['avatar']),
                    ),
                  ),
                ),
                if (isUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.purpleColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTheme.blackTextStyle.copyWith(
                        fontSize: 14,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(
                          text: "${item['name']} ",
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: item['content'],
                          style: TextStyle(
                            color: isUnread
                                ? AppColors.blackColor
                                : AppColors.greyColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['time'],
                    style: AppTheme.greyTextStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Action Preview (Post Image or Follow Button)
            if (item['postImage'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  item['postImage'],
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.purpleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.image,
                        color: AppColors.purpleColor.withOpacity(0.5),
                        size: 20,
                      ),
                    );
                  },
                ),
              )
            else if (item['type'] == 2)
              _buildFollowButton(item),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          item['type'] = 0; // Change type to prevent showing button again
          item['content'] = 'You followed back.';
          item['isUnread'] = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.purpleColor,
              AppColors.purpleColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.purpleColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Follow',
          style: AppTheme.whiteTextStyle.copyWith(
            fontSize: 12,
            fontWeight: AppTheme.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBlurBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundColor.withOpacity(0),
                AppColors.backgroundColor.withOpacity(0.8),
                AppColors.backgroundColor,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
