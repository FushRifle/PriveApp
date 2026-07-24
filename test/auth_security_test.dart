import 'package:clique/bloc/auth/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authentication events do not stringify passwords', () {
    const password = 'never-log-this-password';
    const signIn = SignInRequested(
      email: 'person@example.com',
      password: password,
      rememberMe: false,
    );
    const signUp = SignUpRequested(
      email: 'person@example.com',
      password: password,
      firstName: 'Test',
      lastName: 'Person',
    );

    expect(signIn.toString(), isNot(contains(password)));
    expect(signUp.toString(), isNot(contains(password)));
  });
}
