import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clique/core/clients/supabase_client.dart';

class AuthSessionSnapshot {
  final Session session;
  final User? user;

  const AuthSessionSnapshot({required this.session, required this.user});
}

class AuthRefreshCoordinator<T> {
  Future<T>? _inFlight;

  Future<T> run(Future<T> Function() operation) {
    final existing = _inFlight;
    if (existing != null) return existing;

    final future = operation();
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }
}

class AuthSessionManager {
  AuthSessionManager._();

  static final AuthSessionManager instance = AuthSessionManager._();

  final AuthRefreshCoordinator<Session?> _refreshCoordinator =
      AuthRefreshCoordinator<Session?>();

  Session? get currentSession => SupabaseConfig.client.auth.currentSession;

  User? get currentUser => SupabaseConfig.client.auth.currentUser;

  AuthSessionSnapshot? get currentSnapshot {
    final session = currentSession;
    if (session == null) return null;
    return AuthSessionSnapshot(session: session, user: currentUser);
  }

  Future<AuthSessionSnapshot?> restoreSession() async {
    final session = await getFreshSession();
    if (session == null) return null;
    return AuthSessionSnapshot(session: session, user: currentUser);
  }

  Future<Session?> getFreshSession() async {
    final session = currentSession;
    if (session == null) return null;

    final expiresAt = session.expiresAt;
    if (expiresAt == null || !_expiresSoon(expiresAt)) return session;

    return _refreshCoordinator.run(() async {
      _log('auth_session_refresh_started');
      try {
        final response = await SupabaseConfig.client.auth.refreshSession();
        _log(
          'auth_session_refresh_completed',
          fields: {'has_session': response.session != null},
        );
        return response.session;
      } catch (error) {
        _log(
          'auth_session_refresh_failed',
          fields: {'error_type': error.runtimeType.toString()},
        );
        rethrow;
      }
    });
  }

  bool _expiresSoon(int expiresAt) {
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return !expiry.isAfter(DateTime.now().add(const Duration(minutes: 2)));
  }

  void _log(String event, {Map<String, Object?> fields = const {}}) {
    debugPrint(jsonEncode({'event': event, ...fields}));
  }
}
