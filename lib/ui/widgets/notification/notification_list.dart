import 'package:clique/ui/widgets/notification/notification_empty_state.dart';
import 'package:clique/ui/widgets/notification/notification_item.dart';
import 'package:clique/ui/widgets/notification/notification_loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:clique/app/configs/colors.dart';

class NotificationList extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<List<int>> onMarkAsRead;
  final ValueChanged<List<int>> onDelete;

  const NotificationList({
    super.key,
    required this.notifications,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        widget.isLoadingMore ||
        !widget.hasMore) {
      return;
    }
    if (_scrollController.position.extentAfter < 420) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.notifications.isEmpty) {
      return const NotificationLoadingShimmer();
    }

    if (widget.notifications.isEmpty) {
      return NotificationEmptyState(
        isError: widget.error != null,
        onRetry: widget.error == null ? null : widget.onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.secondary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount:
            widget.notifications.length + 1 + (widget.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildNewestHeader();
          }
          final notificationIndex = index - 1;
          if (notificationIndex >= widget.notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return NotificationItem(
            notification: widget.notifications[notificationIndex],
            onMarkAsRead: widget.onMarkAsRead,
            onDelete: widget.onDelete,
          );
        },
      ),
    );
  }

  Widget _buildNewestHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
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
