import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clique/app/configs/colors.dart';
import 'package:clique/bloc/notification/notification_bloc.dart';
import 'package:clique/ui/widgets/common/app_page_header.dart';
import 'package:clique/ui/widgets/notification/notification_list.dart';
import 'package:clique/ui/widgets/notification/notification_utils.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationBloc()..add(const LoadNotifications()),
      child: const _NotificationView(),
    );
  }
}

class _NotificationView extends StatelessWidget {
  const _NotificationView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: BlocConsumer<NotificationBloc, NotificationState>(
        listenWhen: (previous, current) =>
            previous.error != current.error &&
            current.error != null &&
            current.hasContent,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.error!),
                behavior: SnackBarBehavior.floating,
              ),
            );
          context.read<NotificationBloc>().add(ClearNotificationError());
        },
        builder: (context, state) {
          final grouped = _groupNotifications(
            state.notifications
                .map(
                  (item) => <String, dynamic>{
                    ...item.toJson(),
                    'isUnread': !item.isRead,
                  },
                )
                .toList(),
          );

          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Column(
              children: [
                AppPageHeader(
                  title: 'Notifications',
                  subtitle: state.notifications.isEmpty
                      ? 'Recent activity'
                      : state.totalUnreadCount == 0
                          ? '${state.notifications.length} updates'
                          : '${state.totalUnreadCount} unread',
                  leadingIcon: Icons.arrow_back_ios_new_rounded,
                  onLeadingTap: () => Navigator.pop(context),
                  actionIcon: state.totalUnreadCount > 0
                      ? Icons.done_all_rounded
                      : null,
                  onActionTap: state.totalUnreadCount > 0
                      ? () {
                          HapticFeedback.lightImpact();
                          context
                              .read<NotificationBloc>()
                              .add(MarkAllNotificationsAsRead());
                        }
                      : null,
                ),
                Expanded(
                  child: NotificationList(
                    notifications: grouped,
                    isLoading: state.isInitialLoading,
                    isLoadingMore: state.isLoadingMore,
                    hasMore: state.hasMore,
                    error: state.error,
                    onRefresh: () async {
                      context
                          .read<NotificationBloc>()
                          .add(const RefreshNotifications());
                      await context.read<NotificationBloc>().stream.firstWhere(
                            (next) => !next.isRefreshing,
                          );
                    },
                    onLoadMore: () => context
                        .read<NotificationBloc>()
                        .add(LoadMoreNotifications()),
                    onMarkAsRead: (ids) {
                      for (final id in ids) {
                        context.read<NotificationBloc>().add(
                              MarkNotificationAsRead(notificationId: id),
                            );
                      }
                    },
                    onDelete: (ids) {
                      for (final id in ids) {
                        context.read<NotificationBloc>().add(
                              DeleteNotification(notificationId: id),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
            data['fromUserId'],
      );
      grouped.putIfAbsent('$type:$actorId', () => []).add(item);
    }

    final result = <Map<String, dynamic>>[];
    for (final items in grouped.values) {
      items.sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
      final representative = Map<String, dynamic>.from(items.first)
        ..['groupItems'] = items
        ..['groupCount'] = items.length
        ..['isUnread'] = items.any((item) => item['isUnread'] == true);
      result.add(representative);
    }
    result.addAll(passthrough);
    result.sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
    return result;
  }

  DateTime _createdAt(Map<String, dynamic> item) {
    return DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
