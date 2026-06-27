import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:clique/core/services/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService({required this.restore, this.fallback});

  final Future<AuthResult> Function() restore;
  final AuthResult? fallback;

  @override
  Future<AuthResult> restoreSession() => restore();

  @override
  AuthResult? currentSessionFallback() => fallback;
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
}
