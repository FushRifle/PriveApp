part of 'auth_bloc.dart';

class AuthState extends Equatable {
  final AuthStatus status;
  final bool isAuthenticated;
  final String? token;
  final Map<String, dynamic>? user;
  final String? error;
  final bool isLoading;
  final bool needsVerification;
  final Map<String, dynamic>? savedCredentials;

  const AuthState({
    this.status = AuthStatus.initial,
    this.isAuthenticated = false,
    this.token,
    this.user,
    this.error,
    this.isLoading = false,
    this.needsVerification = false,
    this.savedCredentials,
  });

  AuthState copyWith({
    AuthStatus? status,
    bool? isAuthenticated,
    String? token,
    Map<String, dynamic>? user,
    String? error,
    bool? isLoading,
    bool? needsVerification,
    Map<String, dynamic>? savedCredentials,
  }) {
    return AuthState(
      status: status ?? this.status,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      user: user ?? this.user,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      needsVerification: needsVerification ?? this.needsVerification,
      savedCredentials: savedCredentials ?? this.savedCredentials,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isAuthenticated,
        token,
        user,
        error,
        isLoading,
        needsVerification,
        savedCredentials,
      ];
}

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  verificationRequired,
  error,
}
