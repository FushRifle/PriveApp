import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/core/services/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService({
    required this.restore,
    this.fallback,
    this.signUpResult,
  });

  final Future<AuthResult> Function() restore;
  final AuthResult? fallback;
  final AuthResult? signUpResult;

  @override
  Future<AuthResult> restoreSession() => restore();

  @override
  AuthResult? currentSessionFallback() => fallback;

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async =>
      signUpResult ?? AuthResult(success: false);
}

void main() {
  test('keeps a local session when refresh temporarily fails', () async {
    final fallback = AuthResult(
      success: true,
      token: 'stored-token',
      user: const {'id': 'user-1'},
    );
    final bloc = AuthBloc(
      authService: _FakeAuthService(
        restore: () => Future<AuthResult>.error(StateError('offline')),
        fallback: fallback,
      ),
    );
    addTearDown(bloc.close);

    final state = await bloc.stream.firstWhere(
      (state) => state.status == AuthStatus.authenticated,
    );

    expect(state.isAuthenticated, isTrue);
    expect(state.token, 'stored-token');
    expect(state.user?['id'], 'user-1');
  });

  test('reports unauthenticated only when no session exists', () async {
    final bloc = AuthBloc(
      authService: _FakeAuthService(
        restore: () async => AuthResult(success: false),
      ),
    );
    addTearDown(bloc.close);

    final state = await bloc.stream.firstWhere(
      (state) => state.status == AuthStatus.unauthenticated,
    );

    expect(state.isAuthenticated, isFalse);
    expect(state.token, isNull);
  });

  test('marks the session as a new registration after sign up', () async {
    final bloc = AuthBloc(
      authService: _FakeAuthService(
        restore: () async => AuthResult(success: false),
        signUpResult: AuthResult(
          success: true,
          token: 'new-token',
          user: const {'id': 'new-user'},
        ),
      ),
    );
    addTearDown(bloc.close);
    await bloc.stream.firstWhere(
      (state) => state.status == AuthStatus.unauthenticated,
    );

    bloc.add(const SignUpRequested(
      email: 'new@example.com',
      password: 'password123',
      firstName: '',
      lastName: '',
    ));
    final state = await bloc.stream.firstWhere(
      (state) => state.status == AuthStatus.authenticated,
    );

    expect(state.isNewRegistration, isTrue);
  });
}
