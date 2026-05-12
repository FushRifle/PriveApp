import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:Prive/data/services/notification/notification_service.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _notificationService = NotificationService();
  static const int _pageSize = 20;

  NotificationBloc() : super(const NotificationState()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<LoadMoreNotifications>(_onLoadMoreNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<DeleteAllNotifications>(_onDeleteAllNotifications);
    on<LoadNotificationPreferences>(_onLoadNotificationPreferences);
    on<UpdateNotificationPreferences>(_onUpdateNotificationPreferences);
    on<TogglePushNotifications>(_onTogglePushNotifications);
    on<ToggleEmailNotifications>(_onToggleEmailNotifications);
    on<ToggleLikeNotifications>(_onToggleLikeNotifications);
    on<ToggleCommentNotifications>(_onToggleCommentNotifications);
    on<ToggleFollowNotifications>(_onToggleFollowNotifications);
    on<ToggleMessageNotifications>(_onToggleMessageNotifications);
    on<FilterNotifications>(_onFilterNotifications);
    on<ClearNotificationFilter>(_onClearNotificationFilter);
    on<ClearUnreadCount>(_onClearUnreadCount);
    on<NewNotificationReceived>(_onNewNotificationReceived);
    on<ClearNotificationError>(_onClearNotificationError);
    on<ResetNotificationState>(_onResetNotificationState);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.notifications.isEmpty) {
      emit(state.copyWith(
        status: NotificationStatus.loading,
        isLoading: true,
      ));
    }

    try {
      final result = await _notificationService.getNotifications(
        page: event.page,
        pageSize: _pageSize,
        unreadOnly: event.unreadOnly,
      );

      final notifications = (result['notifications'] as List?)
              ?.map((n) => NotificationItem.fromJson(n))
              .toList() ??
          [];

      emit(state.copyWith(
        notifications: notifications,
        hasMore: notifications.length >= _pageSize,
        currentPage: event.page,
        totalUnreadCount: result['unreadCount'] ?? 0,
        status: NotificationStatus.success,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(
      status: NotificationStatus.refreshing,
      isRefreshing: true,
    ));

    try {
      final result = await _notificationService.getNotifications(
        page: 1,
        pageSize: _pageSize,
        unreadOnly: event.unreadOnly,
      );

      final notifications = (result['notifications'] as List?)
              ?.map((n) => NotificationItem.fromJson(n))
              .toList() ??
          [];

      emit(state.copyWith(
        notifications: notifications,
        hasMore: notifications.length >= _pageSize,
        currentPage: 1,
        totalUnreadCount: result['unreadCount'] ?? 0,
        status: NotificationStatus.success,
        isRefreshing: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreNotifications(
    LoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore || state.isRefreshing) return;

    emit(state.copyWith(
      status: NotificationStatus.loadingMore,
      isLoadingMore: true,
    ));

    try {
      final nextPage = state.currentPage + 1;
      final result = await _notificationService.getNotifications(
        page: nextPage,
        pageSize: _pageSize,
      );

      final newNotifications = (result['notifications'] as List?)
              ?.map((n) => NotificationItem.fromJson(n))
              .toList() ??
          [];

      final updatedNotifications = [
        ...state.notifications,
        ...newNotifications
      ];

      emit(state.copyWith(
        notifications: updatedNotifications,
        hasMore: newNotifications.length >= _pageSize,
        currentPage: nextPage,
        status: NotificationStatus.success,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic update
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == event.notificationId && !n.isRead) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

    emit(state.copyWith(
      notifications: updatedNotifications,
      totalUnreadCount: newUnreadCount,
    ));

    try {
      await _notificationService.markAsRead(event.notificationId);
    } catch (e) {
      // Rollback on error
      final rolledBackNotifications = state.notifications.map((n) {
        if (n.id == event.notificationId) {
          return n.copyWith(isRead: false);
        }
        return n;
      }).toList();

      final rolledBackUnreadCount =
          rolledBackNotifications.where((n) => !n.isRead).length;

      emit(state.copyWith(
        notifications: rolledBackNotifications,
        totalUnreadCount: rolledBackUnreadCount,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic update - mark all as read
    final updatedNotifications = state.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();

    emit(state.copyWith(
      notifications: updatedNotifications,
      totalUnreadCount: 0,
    ));

    try {
      await _notificationService.markAllAsRead();
    } catch (e) {
      // Refresh to restore correct state
      add(RefreshNotifications());
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic update - remove notification
    final updatedNotifications =
        state.notifications.where((n) => n.id != event.notificationId).toList();

    final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

    emit(state.copyWith(
      notifications: updatedNotifications,
      totalUnreadCount: newUnreadCount,
      isDeleting: true,
    ));

    try {
      await _notificationService.deleteNotification(event.notificationId);
      emit(state.copyWith(isDeleting: false));
    } catch (e) {
      // Refresh to restore correct state
      add(RefreshNotifications());
      emit(state.copyWith(
        isDeleting: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteAllNotifications(
    DeleteAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(
      isDeleting: true,
    ));

    try {
      await _notificationService.deleteAllNotifications();
      emit(state.copyWith(
        notifications: [],
        totalUnreadCount: 0,
        hasMore: false,
        isDeleting: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isDeleting: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadNotificationPreferences(
    LoadNotificationPreferences event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(
      preferencesStatus: NotificationStatus.loading,
    ));

    try {
      final prefs = await _notificationService.getPreferences();
      emit(state.copyWith(
        preferences: NotificationPreferences.fromJson(prefs),
        preferencesStatus: NotificationStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
        preferencesStatus: NotificationStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateNotificationPreferences(
    UpdateNotificationPreferences event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final result =
          await _notificationService.updatePreferences(event.preferences);
      emit(state.copyWith(
        preferences: NotificationPreferences.fromJson(result),
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // Convenience toggle methods
  Future<void> _onTogglePushNotifications(
    TogglePushNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.preferences == null) return;
    final updatedPrefs =
        state.preferences!.copyWith(pushEnabled: event.enabled);
    add(UpdateNotificationPreferences(preferences: updatedPrefs.toJson()));
  }

  Future<void> _onToggleEmailNotifications(
    ToggleEmailNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.preferences == null) return;
    final updatedPrefs =
        state.preferences!.copyWith(emailEnabled: event.enabled);
    add(UpdateNotificationPreferences(preferences: updatedPrefs.toJson()));
  }

  Future<void> _onToggleLikeNotifications(
    ToggleLikeNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.preferences == null) return;
    final updatedPrefs =
        state.preferences!.copyWith(likeNotifications: event.enabled);
    add(UpdateNotificationPreferences(preferences: updatedPrefs.toJson()));
  }

  Future<void> _onToggleCommentNotifications(
    ToggleCommentNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.preferences == null) return;
    final updatedPrefs =
        state.preferences!.copyWith(commentNotifications: event.enabled);
    add(UpdateNotificationPreferences(preferences: updatedPrefs.toJson()));
  }

  Future<void> _onToggleFollowNotifications(
    ToggleFollowNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.preferences == null) return;
    final updatedPrefs =
        state.preferences!.copyWith(followNotifications: event.enabled);
    add(UpdateNotificationPreferences(preferences: updatedPrefs.toJson()));
  }

  Future<void> _onToggleMessageNotifications(
    ToggleMessageNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.preferences == null) return;
    final updatedPrefs =
        state.preferences!.copyWith(messageNotifications: event.enabled);
    add(UpdateNotificationPreferences(preferences: updatedPrefs.toJson()));
  }

  void _onFilterNotifications(
    FilterNotifications event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(
      filterType: event.type,
      filterFromDate: event.fromDate,
      filterToDate: event.toDate,
    ));
    add(RefreshNotifications());
  }

  void _onClearNotificationFilter(
    ClearNotificationFilter event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(
      filterType: null,
      filterFromDate: null,
      filterToDate: null,
    ));
    add(RefreshNotifications());
  }

  void _onClearUnreadCount(
    ClearUnreadCount event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(totalUnreadCount: 0));
  }

  void _onNewNotificationReceived(
    NewNotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    final newNotification = NotificationItem.fromJson(event.notification);

    // Add to beginning of list if not already present
    final exists = state.notifications.any((n) => n.id == newNotification.id);
    if (!exists) {
      final updatedNotifications = [newNotification, ...state.notifications];
      final newUnreadCount =
          state.totalUnreadCount + (newNotification.isRead ? 0 : 1);

      emit(state.copyWith(
        notifications: updatedNotifications,
        totalUnreadCount: newUnreadCount,
      ));
    }
  }

  void _onClearNotificationError(
    ClearNotificationError event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(error: null));
  }

  void _onResetNotificationState(
    ResetNotificationState event,
    Emitter<NotificationState> emit,
  ) {
    emit(const NotificationState());
  }
}
