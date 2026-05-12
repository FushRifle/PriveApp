import 'package:dio/dio.dart';
import '../../../core/api_service.dart';

class UploadService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>?> getUploadSignature({
    required String folder,
    List<String>? tags,
    String resourceType = 'image',
  }) async {
    try {
      final response = await _api.post('/api/upload/sign', data: {
        'folder': folder,
        'tags': tags ?? [],
        'resourceType': resourceType,
      });

      print('Signature response: ${response.statusCode}');
      print('Signature data: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      print('Upload sign error: ${e.response?.data}');
      print('Upload sign error status: ${e.response?.statusCode}');
      return null;
    } catch (e) {
      print('Upload sign unexpected error: $e');
      return null;
    }
  }

  Future<void> deleteImage(String publicId) async {
    try {
      await _api.delete('/api/upload/$publicId');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete image';
    }
  }
}
