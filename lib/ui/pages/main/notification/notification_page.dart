import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clique/app/configs/colors.dart';
import 'package:clique/core/services/notification/notification_service.dart';

import 'package:clique/ui/widgets/common/app_page_header.dart';
import 'package:clique/ui/widgets/notification/notification_utils.dart';
import 'package:clique/ui/widgets/notification/notification_list.dart';


class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _groupedNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await _notificationService.getNotifications(
        page: 1,
        pageSize: 20,
      );
      
      if (!mounted) return;
      
      final notifications = (response['notifications'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      
      setState(() {
        _notifications = notifications;
        _groupedNotifications = _groupNotifications(notifications);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _groupNotifications(
    List<Map<String, dynamic>> notifications,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    final passthrough = <Map<String, dynamic>>[];

    for (final item in notifications) {
      final type = item['type']?.toString() ?? 'general';
      if (!NotificationUtils.shouldGroup(type)) {
        passthrough.add(item);
        continue;
      }

      final data = NotificationUtils.asMap(item['data']);
      final actorId = NotificationUtils.readInt(
        item['actorId'] ??
            data['actorId'] ??
            data['actorUserId'] ??
            data['fromUserId'] ??
            data['likerUserId'] ??
            data['commenterUserId'] ??
            data['followerUserId'],
      );

      final key = '$type:$actorId';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    final result = <Map<String, dynamic>>[];

    for (final entry in grouped.entries) {
      final items = [...entry.value]..sort((a, b) {
          final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

      final representative = Map<String, dynamic>.from(items.first);
      representative['groupItems'] = items;
      representative['groupCount'] = items.length;
      representative['isUnread'] =
          items.any((item) => item['isUnread'] == true);
      result.add(representative);
    }

    result.addAll(passthrough);

    result.sort((a, b) {
      final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return result;
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (!mounted) return;
      
      setState(() {
        for (var notification in _notifications) {
          notification['isUnread'] = false;
        }
        _groupedNotifications = _groupNotifications(_notifications);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark all as read: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  int get _unreadCount {
    return _notifications.where((n) => n['isUnread'] == true).length;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Notifications',
            subtitle: _notifications.isEmpty
                ? 'Recent activity'
                : '$_unreadCount unread',
            leadingIcon: Icons.arrow_back_ios_new,
            onLeadingTap: () => Navigator.pop(context),
            actionIcon: _unreadCount > 0
                ? Icons.done_all_rounded
                : Icons.more_vert_rounded,
            onActionTap: _unreadCount > 0 ? _markAllAsRead : null,
          ),
          Expanded(
            child: NotificationList(
              notifications: _groupedNotifications,
              isLoading: _isLoading,
              onRefresh: _loadNotifications,
            ),
          ),
        ],
      ),
    );
  }
}