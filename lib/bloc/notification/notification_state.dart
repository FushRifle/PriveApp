part of 'notification_bloc.dart';

class NotificationItem {
  final int id;
  final String type; // 'like', 'comment', 'follow', 'message', 'match'
  final String title;
  final String message;
  final String? imageUrl;
  final int? actorId;
  final String? actorName;
  final String? actorAvatar;
  final int? targetId;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.imageUrl,
    this.actorId,
    this.actorName,
    this.actorAvatar,
    this.targetId,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      actorId: json['actorId'],
      actorName: json['actorName']?.toString(),
      actorAvatar: json['actorAvatar']?.toString(),
      targetId: json['targetId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      isRead: json['isRead'] == true || json['read'] == true,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'message': message,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (actorId != null) 'actorId': actorId,
        if (actorName != null) 'actorName': actorName,
        if (actorAvatar != null) 'actorAvatar': actorAvatar,
        if (targetId != null) 'targetId': targetId,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        if (data != null) 'data': data,
      };

  NotificationItem copyWith({
    int? id,
    String? type,
    String? title,
    String? message,
    String? imageUrl,
    int? actorId,
    String? actorName,
    String? actorAvatar,
    int? targetId,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorAvatar: actorAvatar ?? this.actorAvatar,
      targetId: targetId ?? this.targetId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

class NotificationPreferences {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool likeNotifications;
  final bool commentNotifications;
  final bool followNotifications;
  final bool messageNotifications;
  final bool matchNotifications;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.likeNotifications = true,
    this.commentNotifications = true,
    this.followNotifications = true,
    this.messageNotifications = true,
    this.matchNotifications = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['pushEnabled'] ?? true,
      emailEnabled: json['emailEnabled'] ?? true,
      likeNotifications: json['likeNotifications'] ?? true,
      commentNotifications: json['commentNotifications'] ?? true,
      followNotifications: json['followNotifications'] ?? true,
      messageNotifications: json['messageNotifications'] ?? true,
      matchNotifications: json['matchNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'pushEnabled': pushEnabled,
        'emailEnabled': emailEnabled,
        'likeNotifications': likeNotifications,
        'commentNotifications': commentNotifications,
        'followNotifications': followNotifications,
        'messageNotifications': messageNotifications,
        'matchNotifications': matchNotifications,
      };

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? likeNotifications,
    bool? commentNotifications,
    bool? followNotifications,
    bool? messageNotifications,
    bool? matchNotifications,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      likeNotifications: likeNotifications ?? this.likeNotifications,
      commentNotifications: commentNotifications ?? this.commentNotifications,
      followNotifications: followNotifications ?? this.followNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      matchNotifications: matchNotifications ?? this.matchNotifications,
    );
  }
}

class NotificationState extends Equatable {
  // Notifications
  final List<NotificationItem> notifications;
  final bool hasMore;
  final int currentPage;
  final int totalUnreadCount;

  // Filter
  final String? filterType;
  final DateTime? filterFromDate;
  final DateTime? filterToDate;

  // Preferences
  final NotificationPreferences? preferences;

  // Status
  final NotificationStatus status;
  final NotificationStatus preferencesStatus;
  final String? error;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool isDeleting;

  const NotificationState({
    this.notifications = const [],
    this.hasMore = true,
    this.currentPage = 1,
    this.totalUnreadCount = 0,
    this.filterType,
    this.filterFromDate,
    this.filterToDate,
    this.preferences,
    this.status = NotificationStatus.initial,
    this.preferencesStatus = NotificationStatus.initial,
    this.error,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.isDeleting = false,
  });

  // Helper getters
  int get unreadCount => notifications.where((n) => !n.isRead).length;
  bool get hasFilters =>
      filterType != null || filterFromDate != null || filterToDate != null;

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? hasMore,
    int? currentPage,
    int? totalUnreadCount,
    String? filterType,
    DateTime? filterFromDate,
    DateTime? filterToDate,
    NotificationPreferences? preferences,
    NotificationStatus? status,
    NotificationStatus? preferencesStatus,
    String? error,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? isDeleting,
    bool clearError = false,
    bool clearFilterType = false,
    bool clearFilterFromDate = false,
    bool clearFilterToDate = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      filterType: clearFilterType ? null : filterType ?? this.filterType,
      filterFromDate:
          clearFilterFromDate ? null : filterFromDate ?? this.filterFromDate,
      filterToDate:
          clearFilterToDate ? null : filterToDate ?? this.filterToDate,
      preferences: preferences ?? this.preferences,
      status: status ?? this.status,
      preferencesStatus: preferencesStatus ?? this.preferencesStatus,
      error: clearError ? null : error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        hasMore,
        currentPage,
        totalUnreadCount,
        filterType,
        filterFromDate,
        filterToDate,
        preferences,
        status,
        preferencesStatus,
        error,
        isLoading,
        isLoadingMore,
        isRefreshing,
        isDeleting,
      ];
}

enum NotificationStatus {
  initial,
  loading,
  loadingMore,
  refreshing,
  success,
  error,
}
