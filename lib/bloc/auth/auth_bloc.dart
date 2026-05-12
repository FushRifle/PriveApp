import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:Prive/data/services/auth/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();

  AuthBloc() : super(const AuthState()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoadSavedCredentials>(_onLoadSavedCredentials);
    on<SaveCredentialsRequested>(_onSaveCredentialsRequested);
    on<ClearAuthError>(_onClearAuthError);

    // Check auth status on initialization
    add(CheckAuthStatus());
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      isLoading: true,
      error: null,
      needsVerification: false,
    ));

    final result = await _authService.signIn(event.email, event.password);

    if (result.success && result.token != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        isAuthenticated: true,
        token: result.token,
        user: result.user,
        isLoading: false,
        error: null,
        needsVerification: false,
      ));
    } else if (result.needsVerification) {
      emit(state.copyWith(
        status: AuthStatus.verificationRequired,
        isLoading: false,
        error: result.error,
        needsVerification: true,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.error,
        isAuthenticated: false,
        isLoading: false,
        error: result.error ?? 'Sign in failed',
        needsVerification: false,
      ));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      isLoading: true,
      error: null,
      needsVerification: false,
    ));

    final result = await _authService.signUp(
      email: event.email,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
    );

    if (result.success && result.token != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        isAuthenticated: true,
        token: result.token,
        user: result.user,
        isLoading: false,
        error: null,
        needsVerification: false,
      ));
    } else if (result.needsVerification) {
      emit(state.copyWith(
        status: AuthStatus.verificationRequired,
        isLoading: false,
        error: result.error,
        needsVerification: true,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.error,
        isAuthenticated: false,
        isLoading: false,
        error: result.error ?? 'Sign up failed',
        needsVerification: false,
      ));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      isLoading: true,
    ));

    await _authService.signOut();

    emit(const AuthState(
      status: AuthStatus.unauthenticated,
      isAuthenticated: false,
      isLoading: false,
    ));
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final isAuthenticated = await _authService.isAuthenticated();
    final token = await _authService.getToken();

    if (isAuthenticated && token != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        isAuthenticated: true,
        token: token,
        isLoading: false,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isAuthenticated: false,
        token: null,
        user: null,
        isLoading: false,
      ));
    }
  }

  Future<void> _onLoadSavedCredentials(
    LoadSavedCredentials event,
    Emitter<AuthState> emit,
  ) async {
    final credentials = await _authService.getSavedCredentials();
    emit(state.copyWith(
      savedCredentials: credentials,
    ));
  }

  Future<void> _onSaveCredentialsRequested(
    SaveCredentialsRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.saveCredentials(
      event.email,
      event.password,
      event.rememberMe,
    );

    if (event.rememberMe) {
      emit(state.copyWith(
        savedCredentials: {
          'rememberMe': true,
          'email': event.email,
          'password': event.password,
        },
      ));
    } else {
      emit(state.copyWith(
        savedCredentials: {
          'rememberMe': false,
          'email': '',
          'password': '',
        },
      ));
    }
  }

  void _onClearAuthError(
    ClearAuthError event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      error: null,
      status: AuthStatus.unauthenticated,
    ));
  }
}
