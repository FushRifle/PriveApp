import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token data model
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get needsRefresh => expiresAt.difference(DateTime.now()).inMinutes < 5; // Refresh if expiring soon

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'],
        refreshToken: json['refreshToken'],
        expiresAt: DateTime.parse(json['expiresAt']),
      );
}

/// Token Manager with secure storage and race condition prevention
class TokenManager {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'expires_at';
  
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static final StreamController<AuthTokens?> _tokenStreamController = 
      StreamController<AuthTokens?>.broadcast();
  
  // Lock for concurrent refresh operations
  static Completer<AuthTokens>? _refreshCompleter;
  static bool _isRefreshing = false;

  /// Stream to listen for token changes (useful for UI updates)
  static Stream<AuthTokens?> get tokenStream => _tokenStreamController.stream;

  /// Get current access token synchronously from memory (fast, but not secure)
  static String? _cachedAccessToken;
  static AuthTokens? _cachedTokens;

  /// Initialize token manager (call in main.dart)
  static Future<void> init() async {
    final tokens = await loadTokens();
    if (tokens != null) {
      _cachedTokens = tokens;
      _cachedAccessToken = tokens.accessToken;
    }
  }

  /// Save tokens securely
  static Future<void> saveTokens(AuthTokens tokens, {required accessToken}) async {
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: tokens.accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: tokens.refreshToken),
      _secureStorage.write(key: _expiresAtKey, value: tokens.expiresAt.toIso8601String()),
    ]);
    
    _cachedTokens = tokens;
    _cachedAccessToken = tokens.accessToken;
    _tokenStreamController.add(tokens);
  }

  /// Load tokens from secure storage
  static Future<AuthTokens?> loadTokens() async {
    try {
      final results = await Future.wait([
        _secureStorage.read(key: _accessTokenKey),
        _secureStorage.read(key: _refreshTokenKey),
        _secureStorage.read(key: _expiresAtKey),
      ]);

      final accessToken = results[0];
      final refreshToken = results[1];
      final expiresAtStr = results[2];

      if (accessToken == null || refreshToken == null || expiresAtStr == null) {
        return null;
      }

      return AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: DateTime.parse(expiresAtStr),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get access token (returns cached or loads from storage)
  static Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) {
      return _cachedAccessToken;
    }
    
    final tokens = await loadTokens();
    return tokens?.accessToken;
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    final tokens = await loadTokens();
    return tokens?.refreshToken;
  }

  /// Check if token is valid (not expired)
  static Future<bool> isTokenValid() async {
    final tokens = await loadTokens();
    if (tokens == null) return false;
    return !tokens.isExpired;
  }

  /// Refresh tokens (with built-in lock for concurrent calls)
  static Future<AuthTokens> refreshTokens({
    required Future<AuthTokens> Function(String refreshToken) refreshApiCall,
  }) async {
    // If already refreshing, wait for it to complete
    if (_isRefreshing && _refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<AuthTokens>();

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      // Call the API to get new tokens
      final newTokens = await refreshApiCall(refreshToken);
      
      // Save the new tokens
      await saveTokens(newTokens, accessToken: null);
      
      // Complete all waiting futures
      _refreshCompleter!.complete(newTokens);
      _isRefreshing = false;
      _refreshCompleter = null;
      
      return newTokens;
    } catch (e) {
      // On error, clear tokens and notify listeners
      await clearTokens();
      _refreshCompleter!.completeError(e);
      _isRefreshing = false;
      _refreshCompleter = null;
      rethrow;
    }
  }

  /// Clear all tokens (logout)
  static Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _expiresAtKey),
    ]);
    
    _cachedAccessToken = null;
    _cachedTokens = null;
    _tokenStreamController.add(null);
  }

  /// Update access token only (used when backend only returns new access token)
  static Future<void> updateAccessToken(String newAccessToken) async {
    final tokens = await loadTokens();
    if (tokens != null) {
      final updatedTokens = AuthTokens(
        accessToken: newAccessToken,
        refreshToken: tokens.refreshToken,
        expiresAt: tokens.expiresAt,
      );
      await saveTokens(updatedTokens, accessToken: null);
    }
  }
}