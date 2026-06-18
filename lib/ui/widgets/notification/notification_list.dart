import 'package:clique/ui/widgets/notification/notification_empty_state.dart';
import 'package:clique/ui/widgets/notification/notification_item.dart';
import 'package:clique/ui/widgets/notification/notification_loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';

class NotificationList extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
  final VoidCallback onRefresh;

  const NotificationList({
    super.key,
    required this.notifications,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.notifications.isEmpty) {
      return const NotificationLoadingShimmer();
    }

    if (widget.notifications.isEmpty) {
      return const NotificationEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: widget.notifications.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildNewestHeader();
          }
          final notificationIndex = index - 1;
          return NotificationItem(
            notification: widget.notifications[notificationIndex],
          );
        },
      ),
    );
  }

  Widget _buildNewestHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'NEWEST',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            '${widget.notifications.length} items',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}