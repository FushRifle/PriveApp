import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:clique/core/models/event_model.dart';
import 'package:clique/core/services/event/event_service.dart';

part 'event_event.dart';
part 'event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  static const int _pageSize = 10;

  final EventService _service = EventService();
  int _listRequestId = 0;
  bool _loadingMore = false;

  EventBloc() : super(const EventState()) {
    on<LoadEvents>(_onLoadEvents);
    on<SearchEvents>(_onSearchEvents);
    on<LoadMoreEvents>(_onLoadMoreEvents);
    on<CreateEvent>(_onCreateEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<RsvpEvent>(_onRsvpEvent);
    on<ClearEventError>(_onClearError);
  }

  void setAuthToken(String token) {
    _service.setAuthToken(token);
  }

  Future<void> _onLoadEvents(
    LoadEvents event,
    Emitter<EventState> emit,
  ) async {
    final requestId = ++_listRequestId;
    final nextPage = event.refresh ? 1 : event.page;

    emit(state.copyWith(
      status: nextPage == 1 ? EventStatus.loading : state.status,
      clearError: true,
      page: nextPage,
      events: nextPage == 1 ? const [] : state.events,
    ));

    try {
      final events = await _service.getEvents(
        page: nextPage,
        pageSize: _pageSize,
        query: state.query,
        category: state.category,
        forceRefresh: event.refresh,
      );
      if (requestId != _listRequestId) return;

      final merged =
          nextPage == 1 ? events : _dedupe([...state.events, ...events]);

      emit(state.copyWith(
        status: EventStatus.success,
        events: merged,
        page: nextPage,
        hasMore: events.length >= _pageSize,
        clearError: true,
      ));
    } catch (e) {
      if (requestId != _listRequestId) return;
      emit(state.copyWith(status: EventStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSearchEvents(
    SearchEvents event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(
      query: event.query,
      category: event.category,
      clearError: true,
    ));
    add(const LoadEvents(refresh: true));
  }

  Future<void> _onLoadMoreEvents(
    LoadMoreEvents event,
    Emitter<EventState> emit,
  ) async {
    if (_loadingMore || !state.hasMore) return;
    _loadingMore = true;
    try {
      final nextPage = state.page + 1;
      final events = await _service.getEvents(
        page: nextPage,
        pageSize: _pageSize,
        query: state.query,
        category: state.category,
      );
      emit(state.copyWith(
        events: _dedupe([...state.events, ...events]),
        page: nextPage,
        hasMore: events.length >= _pageSize,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _onCreateEvent(
    CreateEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(actionStatus: EventActionStatus.loading));
    try {
      final created = await _service.createEvent(
        title: event.title,
        description: event.description,
        category: event.category,
        location: event.location,
        startsAt: event.startsAt,
        endsAt: event.endsAt,
        imageUrl: event.imageUrl,
        isPrivate: event.isPrivate,
      );
      emit(state.copyWith(
        actionStatus: EventActionStatus.success,
        events: [created, ...state.events],
        clearError: true,
      ));
      add(const LoadEvents(refresh: true));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: EventActionStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateEvent(
    UpdateEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(actionStatus: EventActionStatus.loading));
    try {
      final updated = await _service.updateEvent(
        eventId: event.eventId,
        title: event.title,
        description: event.description,
        category: event.category,
        location: event.location,
        startsAt: event.startsAt,
        endsAt: event.endsAt,
        imageUrl: event.imageUrl,
        isPrivate: event.isPrivate,
      );

      emit(state.copyWith(
        actionStatus: EventActionStatus.success,
        events: state.events.map((item) {
          if (item.id != event.eventId) return item;
          return updated;
        }).toList(),
        clearError: true,
      ));
      add(const LoadEvents(refresh: true));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: EventActionStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onRsvpEvent(
    RsvpEvent event,
    Emitter<EventState> emit,
  ) async {
    emit(state.copyWith(actionStatus: EventActionStatus.loading));
    try {
      final updated = event.status == 'not_going'
          ? await _service.cancelRsvp(event.eventId)
          : await _service.respondToEvent(event.eventId, event.status);

      emit(state.copyWith(
        actionStatus: EventActionStatus.success,
        events: state.events.map((item) {
          if (item.id != event.eventId) return item;
          return updated;
        }).toList(),
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: EventActionStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _onClearError(ClearEventError event, Emitter<EventState> emit) {
    emit(state.copyWith(clearError: true));
  }

  List<EventModel> _dedupe(List<EventModel> items) {
    final seen = <int>{};
    final result = <EventModel>[];
    for (final item in items) {
      if (seen.add(item.id)) {
        result.add(item);
      }
    }
    return result;
  }
}
