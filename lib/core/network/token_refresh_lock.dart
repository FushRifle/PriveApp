import 'dart:async';

class TokenRefreshLock {
  static Completer<String>? _refreshCompleter;
  static bool _isLoggedOut = false;

  static bool get isRefreshing => _refreshCompleter != null;
  static bool get isLoggedOut => _isLoggedOut;

  /// Returns a Completer if this caller should perform the refresh.
  /// Returns null if another refresh is already in progress.
  static Completer<String>? tryAcquire() {
    if (_refreshCompleter == null && !_isLoggedOut) {
      _refreshCompleter = Completer<String>();
      return _refreshCompleter;
    }
    return null;
  }

  static Completer<String>? get currentCompleter => _refreshCompleter;

  static void complete(String newToken) {
    _refreshCompleter?.complete(newToken);
    _refreshCompleter = null;
  }

  static void completeWithError(Object error) {
    _refreshCompleter?.completeError(error);
    _refreshCompleter = null;
    _isLoggedOut = true;  // Prevents infinite retry loops
  }

  static void reset() {
    _refreshCompleter = null;
    _isLoggedOut = false;
  }
}