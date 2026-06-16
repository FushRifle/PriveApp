import 'package:dio/dio.dart';

import 'package:clique/core/clients/api_service.dart';
import 'package:clique/core/models/event_model.dart';

class EventService {
  final ApiService _api = ApiService();

  void setAuthToken(String token) {
    _api.setAuthToken(token);
  }

  Future<List<EventModel>> getEvents({
    int page = 1,
    int pageSize = 10,
    String query = '',
    String category = '',
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _api.get(
        '/api/events/',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (query.isNotEmpty) 'q': query,
          if (category.isNotEmpty) 'category': category,
        },
        forceRefresh: forceRefresh,
      );
      return _readList(response.data)
          .map((item) => EventModel.fromJson(item))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to load events');
    }
  }

  Future<EventModel> createEvent({
    required String title,
    required String description,
    required String category,
    required String location,
    required DateTime startsAt,
    DateTime? endsAt,
    String imageUrl = '',
    bool isPrivate = false,
  }) async {
    try {
      final response = await _api.post(
        '/api/events/',
        data: {
          'title': title,
          'description': description,
          'category': category,
          'location': location,
          'imageUrl': imageUrl,
          'startsAt': startsAt.toUtc().toIso8601String(),
          if (endsAt != null) 'endsAt': endsAt.toUtc().toIso8601String(),
          'isPrivate': isPrivate,
        },
      );
      _clearEventCaches();
      return EventModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to create event');
    }
  }

  Future<EventModel> updateEvent({
    required int eventId,
    required String title,
    required String description,
    required String category,
    required String location,
    required DateTime startsAt,
    DateTime? endsAt,
    String imageUrl = '',
    bool isPrivate = false,
  }) async {
    try {
      final response = await _api.put(
        '/api/events/$eventId',
        data: {
          'title': title,
          'description': description,
          'category': category,
          'location': location,
          'imageUrl': imageUrl,
          'startsAt': startsAt.toUtc().toIso8601String(),
          if (endsAt != null) 'endsAt': endsAt.toUtc().toIso8601String(),
          'isPrivate': isPrivate,
        },
      );
      _clearEventCaches();
      return EventModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to update event');
    }
  }

  Future<EventModel> respondToEvent(int eventId, String status) async {
    try {
      final response = await _api.post(
        '/api/events/$eventId/rsvp',
        data: {'status': status},
      );
      _clearEventCaches();
      return EventModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to update RSVP');
    }
  }

  Future<EventModel> cancelRsvp(int eventId) async {
    try {
      final response = await _api.delete('/api/events/$eventId/rsvp');
      _clearEventCaches();
      return EventModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to leave event');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  List<Map<String, dynamic>> _readList(dynamic data) {
    final raw = data is Map ? data['data'] : data;
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  void _clearEventCaches() {
    _api.removeCacheByPath('/api/events');
  }

  String _handleError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return fallback;
  }
}
