import 'dart:async';

import 'package:clique/core/services/auth/auth_session_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRefreshCoordinator', () {
    test('shares one in-flight refresh across concurrent callers', () async {
      final coordinator = AuthRefreshCoordinator<int>();
      final completer = Completer<int>();
      var calls = 0;

      Future<int> refresh() {
        calls++;
        return completer.future;
      }

      final first = coordinator.run(refresh);
      final second = coordinator.run(refresh);
      expect(calls, 1);

      completer.complete(42);
      expect(await Future.wait([first, second]), [42, 42]);
    });

    test('allows a new refresh after a failed operation', () async {
      final coordinator = AuthRefreshCoordinator<int>();
      var calls = 0;

      Future<int> refresh() async {
        calls++;
        if (calls == 1) throw StateError('temporary failure');
        return 7;
      }

      await expectLater(coordinator.run(refresh), throwsStateError);
      expect(await coordinator.run(refresh), 7);
      expect(calls, 2);
    });
  });
}
