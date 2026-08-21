part of 'event_bloc.dart';

enum EventStatus {
  initial,
  loading,
  success,
  error,
}

enum EventActionStatus {
  initial,
  loading,
  success,
  error,
}

class EventState extends Equatable {
  final EventStatus status;
  final EventActionStatus actionStatus;
  final List<EventModel> events;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final int? activeEventId;
  final String query;
  final String category;
  final String? error;

  const EventState({
    this.status = EventStatus.initial,
    this.actionStatus = EventActionStatus.initial,
    this.events = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.activeEventId,
    this.query = '',
    this.category = '',
    this.error,
  });

  EventState copyWith({
    EventStatus? status,
    EventActionStatus? actionStatus,
    List<EventModel>? events,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    int? activeEventId,
    bool clearActiveEventId = false,
    String? query,
    String? category,
    String? error,
    bool clearError = false,
  }) {
    return EventState(
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      events: events ?? this.events,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      activeEventId:
          clearActiveEventId ? null : activeEventId ?? this.activeEventId,
      query: query ?? this.query,
      category: category ?? this.category,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        actionStatus,
        events,
        page,
        hasMore,
        isLoadingMore,
        activeEventId,
        query,
        category,
        error,
      ];
}
