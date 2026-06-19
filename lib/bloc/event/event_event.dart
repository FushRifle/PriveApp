part of 'event_bloc.dart';

sealed class EventEvent extends Equatable {
  const EventEvent();

  @override
  List<Object?> get props => [];
}

class LoadEvents extends EventEvent {
  final bool refresh;
  final bool silent;
  final int page;

  const LoadEvents({
    this.refresh = false,
    this.silent = false,
    this.page = 1,
  });

  @override
  List<Object?> get props => [refresh, silent, page];
}

class SearchEvents extends EventEvent {
  final String query;
  final String category;

  const SearchEvents({
    required this.query,
    required this.category,
  });

  @override
  List<Object?> get props => [query, category];
}

class LoadMoreEvents extends EventEvent {
  const LoadMoreEvents();
}

class CreateEvent extends EventEvent {
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String imageUrl;
  final bool isPrivate;

  const CreateEvent({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.startsAt,
    this.endsAt,
    this.imageUrl = '',
    this.isPrivate = false,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        category,
        location,
        startsAt,
        endsAt,
        imageUrl,
        isPrivate,
      ];
}

class UpdateEvent extends EventEvent {
  final int eventId;
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String imageUrl;
  final bool isPrivate;

  const UpdateEvent({
    required this.eventId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.startsAt,
    this.endsAt,
    this.imageUrl = '',
    this.isPrivate = false,
  });

  @override
  List<Object?> get props => [
        eventId,
        title,
        description,
        category,
        location,
        startsAt,
        endsAt,
        imageUrl,
        isPrivate,
      ];
}

class RsvpEvent extends EventEvent {
  final int eventId;
  final String status;

  const RsvpEvent({
    required this.eventId,
    required this.status,
  });

  @override
  List<Object?> get props => [eventId, status];
}

class ClearEventError extends EventEvent {
  const ClearEventError();
}
