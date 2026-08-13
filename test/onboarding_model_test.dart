import 'package:clique/core/models/onboarding_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('optional demographics are omitted from the request', () {
    const request = OnboardingProfileRequest();

    expect(request.toJson(), {
      'user': <String, dynamic>{},
      'profile': <String, dynamic>{},
    });
  });
}
