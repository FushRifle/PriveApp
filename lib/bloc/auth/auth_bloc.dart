import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cirqle/data/services/auth/auth_service.dart';

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
    on<VerifyEmailRequested>(_onVerifyEmailRequested);
    on<ResendVerificationCode>(_onResendVerificationCode);
    on<UpdateEmail>(_onUpdateEmail);
    on<UpdatePassword>(_onUpdatePassword);

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

    // Save credentials if remember me is checked
    if (event.rememberMe) {
      await _authService.saveCredentials(event.email, event.password, true);
    }

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
        email: event.email,
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
        email: event.email,
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
    final user = await _authService.getCurrentUser();

    if (isAuthenticated && token != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        isAuthenticated: true,
        token: token,
        user: user,
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

  Future<void> _onVerifyEmailRequested(
    VerifyEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    // In a real implementation, you would verify the code with your backend
    // For now, we'll assume verification is handled by Supabase via email link
    emit(state.copyWith(
      status: AuthStatus.loading,
      isLoading: true,
    ));

    // Simulate verification check
    await Future.delayed(const Duration(seconds: 1));

    // Check if email is now verified
    final isAuthenticated = await _authService.isAuthenticated();
    if (isAuthenticated) {
      final token = await _authService.getToken();
      final user = await _authService.getCurrentUser();
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        isAuthenticated: true,
        token: token,
        user: user,
        isLoading: false,
        needsVerification: false,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.verificationRequired,
        isLoading: false,
        error: 'Invalid or expired verification code',
      ));
    }
  }

  Future<void> _onResendVerificationCode(
    ResendVerificationCode event,
    Emitter<AuthState> emit,
  ) async {
    if (state.email.isEmpty) {
      emit(state.copyWith(
        error: 'Email address not found',
      ));
      return;
    }

    emit(state.copyWith(
      isLoading: true,
      error: null,
    ));

    final success = await _authService.resendVerification(state.email);

    if (success) {
      emit(state.copyWith(
        isLoading: false,
        error: null,
      ));
      // Show success message to user
    } else {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to resend verification code. Please try again.',
      ));
    }
  }

  void _onUpdateEmail(UpdateEmail event, Emitter<AuthState> emit) {
    emit(state.copyWith(email: event.email));
  }

  void _onUpdatePassword(UpdatePassword event, Emitter<AuthState> emit) {
    emit(state.copyWith(password: event.password));
  }
}
