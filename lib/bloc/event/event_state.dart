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
  final String query;
  final String category;
  final String? error;

  const EventState({
    this.status = EventStatus.initial,
    this.actionStatus = EventActionStatus.initial,
    this.events = const [],
    this.page = 1,
    this.hasMore = true,
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
        query,
        category,
        error,
      ];
}
