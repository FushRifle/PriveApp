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

  AuthState copyWith({
    AuthStatus? status,
    bool? isAuthenticated,
    bool? isLoading,
    String? token,
    Map<String, dynamic>? user,
    String? error,
    bool? needsVerification,
    Map<String, dynamic>? savedCredentials,
    String? email,
    String? password,
  }) {
    return AuthState(
      status: status ?? this.status,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      user: user ?? this.user,
      error: error ?? this.error,
      needsVerification: needsVerification ?? this.needsVerification,
      savedCredentials: savedCredentials ?? this.savedCredentials,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

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
