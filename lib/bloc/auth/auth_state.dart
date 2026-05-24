part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  verificationRequired,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;

  final bool isAuthenticated;

  final bool isLoading;

  final String? token;

  final Map<String, dynamic>? user;

  final String? error;

  final bool needsVerification;

  final Map<String, dynamic> savedCredentials;

  final String email;

  final String password;

  const AuthState({
    this.status = AuthStatus.initial,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.token,
    this.user,
    this.error,
    this.needsVerification = false,
    this.savedCredentials = const {},
    this.email = '',
    this.password = '',
  });

  // =========================================================
  // HELPERS
  // =========================================================

  bool get hasError => error != null && error!.trim().isNotEmpty;

  bool get hasUser => user != null;

  bool get hasToken => token != null && token!.isNotEmpty;

  bool get hasSavedCredentials => savedCredentials.isNotEmpty;

  // =========================================================
  // COPY
  // =========================================================

  AuthState copyWith({
    AuthStatus? status,
    bool? isAuthenticated,
    bool? isLoading,
    String? token,
    bool clearToken = false,
    Map<String, dynamic>? user,
    bool clearUser = false,
    String? error,
    bool clearError = false,
    bool? needsVerification,
    Map<String, dynamic>? savedCredentials,
    String? email,
    String? password,
    bool clearPassword = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      token: clearToken ? null : token ?? this.token,
      user: clearUser ? null : user ?? this.user,
      error: clearError ? null : error ?? this.error,
      needsVerification: needsVerification ?? this.needsVerification,
      savedCredentials: savedCredentials ?? this.savedCredentials,
      email: email ?? this.email,
      password: clearPassword ? '' : password ?? this.password,
    );
  }

  // =========================================================
  // FACTORIES
  // =========================================================

  factory AuthState.loading({
    String? email,
  }) {
    return AuthState(
      status: AuthStatus.loading,
      isLoading: true,
      email: email ?? '',
    );
  }

  factory AuthState.authenticated({
    required String token,
    required Map<String, dynamic> user,
  }) {
    return AuthState(
      status: AuthStatus.authenticated,
      isAuthenticated: true,
      token: token,
      user: user,
      isLoading: false,
      needsVerification: false,
    );
  }

  factory AuthState.unauthenticated({
    String? error,
  }) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      isAuthenticated: false,
      error: error,
      isLoading: false,
    );
  }

  factory AuthState.verificationRequired({
    required String email,
    String? error,
  }) {
    return AuthState(
      status: AuthStatus.verificationRequired,
      email: email,
      error: error,
      needsVerification: true,
      isLoading: false,
    );
  }

  factory AuthState.failure(
    String error,
  ) {
    return AuthState(
      status: AuthStatus.error,
      error: error,
      isLoading: false,
      isAuthenticated: false,
    );
  }

  // =========================================================
  // RESET
  // =========================================================

  AuthState reset() {
    return const AuthState();
  }

  // =========================================================
  // PROPS
  // =========================================================

  @override
  List<Object?> get props => [
        status,
        isAuthenticated,
        isLoading,
        token,
        user,
        error,
        needsVerification,
        savedCredentials,
        email,
        password,
      ];
}
