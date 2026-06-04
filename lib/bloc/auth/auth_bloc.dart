import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clique/core/services/auth/auth_service.dart';
import 'package:clique/core/services/notification/push_notification_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();

  bool _isCheckingAuth = false;

  AuthBloc() : super(const AuthState()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoadSavedCredentials>(_onLoadSavedCredentials);
    on<SaveCredentialsRequested>(_onSaveCredentialsRequested);
    on<ClearAuthError>(_onClearAuthError);
    on<VerifyEmailRequested>(_onVerifyEmailRequested);
    on<ResendVerificationCode>(_onResendVerificationCode);
    on<UpdateEmail>(_onUpdateEmail);
    on<UpdatePassword>(_onUpdatePassword);
    add(CheckAuthStatus());
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        isLoading: true,
        clearError: true,
        needsVerification: false,
      ),
    );

    // Save credentials if remember me is checked
    if (event.rememberMe) {
      await _authService.saveCredentials(event.email, event.password, true);
    }

    final result = await _authService.signIn(event.email, event.password);

    if (result.success && result.token != null) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          isAuthenticated: true,
          token: result.token,
          user: result.user,
          isLoading: false,
          clearError: true,
          needsVerification: false,
        ),
      );
    } else if (result.needsVerification) {
      emit(
        state.copyWith(
          status: AuthStatus.verificationRequired,
          isLoading: false,
          error: result.error,
          needsVerification: true,
          email: event.email,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          isAuthenticated: false,
          isLoading: false,
          error: result.error ?? 'Sign in failed',
          needsVerification: false,
        ),
      );
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        isLoading: true,
        clearError: true,
        needsVerification: false,
      ),
    );

    final result = await _authService.signUp(
      email: event.email,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
    );

    if (result.success && result.token != null) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          isAuthenticated: true,
          token: result.token,
          user: result.user,
          isLoading: false,
          clearError: true,
          needsVerification: false,
        ),
      );
    } else if (result.needsVerification) {
      emit(
        state.copyWith(
          status: AuthStatus.verificationRequired,
          isLoading: false,
          error: result.error,
          needsVerification: true,
          email: event.email,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          isAuthenticated: false,
          isLoading: false,
          error: result.error ?? 'Sign up failed',
          needsVerification: false,
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, isLoading: true));

    await PushNotificationService.instance.deleteDeviceToken();
    await _authService.signOut();

    emit(
      const AuthState(
        status: AuthStatus.unauthenticated,
        isAuthenticated: false,
        isLoading: false,
      ),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    if (_isCheckingAuth) return;

    _isCheckingAuth = true;

    if (state.status == AuthStatus.initial) {
      emit(state.copyWith(status: AuthStatus.loading, isLoading: true));
    }

    try {
      final isAuthenticated = await _authService.isAuthenticated();
      final token = await _authService.getToken();
      final user = await _authService.getCurrentUser();

      if (isAuthenticated && token != null) {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            isAuthenticated: true,
            token: token,
            user: user,
            isLoading: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            isAuthenticated: false,
            clearToken: true,
            clearUser: true,
            isLoading: false,
          ),
        );
      }
    } finally {
      _isCheckingAuth = false;
    }
  }

  Future<void> _onLoadSavedCredentials(
    LoadSavedCredentials event,
    Emitter<AuthState> emit,
  ) async {
    final credentials = await _authService.getSavedCredentials();
    emit(state.copyWith(savedCredentials: credentials));
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
  }

  void _onClearAuthError(ClearAuthError event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearError: true));
  }

  Future<void> _onVerifyEmailRequested(
    VerifyEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, isLoading: true));
    await Future.delayed(const Duration(seconds: 1));
    final isAuthenticated = await _authService.isAuthenticated();
    if (isAuthenticated) {
      final token = await _authService.getToken();
      final user = await _authService.getCurrentUser();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          isAuthenticated: true,
          token: token,
          user: user,
          isLoading: false,
          needsVerification: false,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.verificationRequired,
          isLoading: false,
          error: 'Invalid or expired verification code',
        ),
      );
    }
  }

  Future<void> _onResendVerificationCode(
    ResendVerificationCode event,
    Emitter<AuthState> emit,
  ) async {
    if (state.email.isEmpty) {
      emit(state.copyWith(error: 'Email address not found'));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    final success = await _authService.resendVerification(state.email);

    if (success) {
      emit(state.copyWith(isLoading: false, clearError: true));
      // Show success message to user
    } else {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to resend verification code. Please try again.',
        ),
      );
    }
  }

  void _onUpdateEmail(UpdateEmail event, Emitter<AuthState> emit) {
    emit(state.copyWith(email: event.email));
  }

  void _onUpdatePassword(UpdatePassword event, Emitter<AuthState> emit) {
    emit(state.copyWith(password: event.password));
  }
}
