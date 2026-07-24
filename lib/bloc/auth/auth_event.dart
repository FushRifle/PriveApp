part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const SignInRequested({
    required this.email,
    required this.password,
    required this.rememberMe,
  });

  @override
  List<Object?> get props => [email, rememberMe];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  @override
  List<Object?> get props => [email, firstName, lastName];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class LoadSavedCredentials extends AuthEvent {
  const LoadSavedCredentials();
}

class SaveCredentialsRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const SaveCredentialsRequested({
    required this.email,
    required this.password,
    required this.rememberMe,
  });

  @override
  List<Object?> get props => [email, rememberMe];
}

class ClearAuthError extends AuthEvent {
  const ClearAuthError();
}

class VerifyEmailRequested extends AuthEvent {
  final String code;

  const VerifyEmailRequested({required this.code});
}

class ResendVerificationCode extends AuthEvent {
  const ResendVerificationCode();
}

class UpdateEmail extends AuthEvent {
  final String email;

  const UpdateEmail({required this.email});
}
