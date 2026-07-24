import 'package:clique/core/clients/cloudinary_service.dart';
import 'package:clique/core/services/upload/upload_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('upload authorization', () {
    test('parses a complete server-issued signature', () {
      final signature = UploadSignature.fromJson({
        'timestamp': 123,
        'signature': 'signed-value',
        'apiKey': 'public-api-key',
        'cloudName': 'cloud',
        'uploadPreset': 'preset',
        'folder': 'users/user-1/posts',
      });

      expect(signature.timestamp, 123);
      expect(signature.folder, 'users/user-1/posts');
    });

    test('rejects incomplete signatures', () {
      expect(
        () => UploadSignature.fromJson({'timestamp': 123}),
        throwsFormatException,
      );
    });

    test('accepts only backend-supported upload categories', () {
      expect(
        CloudinaryService.normalizeUploadCategory(null, 'audio'),
        'audio',
      );
      expect(
        CloudinaryService.normalizeUploadCategory('avatars', 'image'),
        'avatars',
      );
      expect(
        () => CloudinaryService.normalizeUploadCategory(
          'users/another-user',
          'image',
        ),
        throwsA(isA<UploadException>()),
      );
    });
  });
}
