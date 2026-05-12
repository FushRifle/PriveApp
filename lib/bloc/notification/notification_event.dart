part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

// Load notifications
class LoadNotifications extends NotificationEvent {
  final int page;
  final bool unreadOnly;

  const LoadNotifications({
    this.page = 1,
    this.unreadOnly = false,
  });

  @override
  List<Object?> get props => [page, unreadOnly];
}

// Refresh notifications
class RefreshNotifications extends NotificationEvent {
  final bool unreadOnly;

  const RefreshNotifications({this.unreadOnly = false});

  @override
  List<Object?> get props => [unreadOnly];
}

// Load more notifications (pagination)
class LoadMoreNotifications extends NotificationEvent {}

// Mark notification as read
class MarkNotificationAsRead extends NotificationEvent {
  final int notificationId;

  const MarkNotificationAsRead({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

// Mark all notifications as read
class MarkAllNotificationsAsRead extends NotificationEvent {}

// Delete notification
class DeleteNotification extends NotificationEvent {
  final int notificationId;

  const DeleteNotification({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

// Delete all notifications
class DeleteAllNotifications extends NotificationEvent {}

// Load notification preferences
class LoadNotificationPreferences extends NotificationEvent {}

// Update notification preferences
class UpdateNotificationPreferences extends NotificationEvent {
  final Map<String, dynamic> preferences;

  const UpdateNotificationPreferences({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

// Toggle specific preference (convenience)
class TogglePushNotifications extends NotificationEvent {
  final bool enabled;

  const TogglePushNotifications({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class ToggleEmailNotifications extends NotificationEvent {
  final bool enabled;

  const ToggleEmailNotifications({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class ToggleLikeNotifications extends NotificationEvent {
  final bool enabled;

  const ToggleLikeNotifications({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class ToggleCommentNotifications extends NotificationEvent {
  final bool enabled;

  const ToggleCommentNotifications({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class ToggleFollowNotifications extends NotificationEvent {
  final bool enabled;

  const ToggleFollowNotifications({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class ToggleMessageNotifications extends NotificationEvent {
  final bool enabled;

  const ToggleMessageNotifications({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

// Filter notifications
class FilterNotifications extends NotificationEvent {
  final String? type;
  final DateTime? fromDate;
  final DateTime? toDate;

  const FilterNotifications({
    this.type,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [type, fromDate, toDate];
}

// Clear filter
class ClearNotificationFilter extends NotificationEvent {}

// Clear unread count (for badge)
class ClearUnreadCount extends NotificationEvent {}

// New notification received (from WebSocket/push)
class NewNotificationReceived extends NotificationEvent {
  final Map<String, dynamic> notification;

  const NewNotificationReceived({required this.notification});

  @override
  List<Object?> get props => [notification];
}

// Clear notification error
class ClearNotificationError extends NotificationEvent {}

// Reset notification state
class ResetNotificationState extends NotificationEvent {}
