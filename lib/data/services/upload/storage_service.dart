import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  StorageService._internal();

  // Upload image to Supabase Storage
  Future<String?> uploadImage({
    required XFile file,
    required String folder,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final fileBytes = await file.readAsBytes();
      final fileExt = path.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = '$userId/$folder/$fileName';

      // Upload to Supabase storage
      final response = await _supabase.storage
          .from('posts')
          .uploadBinary(filePath, fileBytes);

      // Get public URL
      final publicUrl = _supabase.storage.from('posts').getPublicUrl(filePath);

      print('Upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading to Supabase: $e');
      return null;
    }
  }

  // Upload video to Supabase Storage
  Future<String?> uploadVideo({
    required XFile file,
    required String folder,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final fileBytes = await file.readAsBytes();
      final fileExt = path.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = '$userId/$folder/$fileName';

      // Upload to Supabase storage
      final response = await _supabase.storage
          .from('videos')
          .uploadBinary(filePath, fileBytes);

      // Get public URL
      final publicUrl = _supabase.storage.from('videos').getPublicUrl(filePath);

      print('Upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading video to Supabase: $e');
      return null;
    }
  }

  // Delete file from Supabase Storage
  Future<bool> deleteFile(String filePath) async {
    try {
      await _supabase.storage.from('posts').remove([filePath]);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Get signed URL for private files
  Future<String?> getSignedUrl(String filePath) async {
    try {
      final response = await _supabase.storage
          .from('posts')
          .createSignedUrl(filePath, 3600); // 1 hour expiry
      return response;
    } catch (e) {
      print('Error getting signed URL: $e');
      return null;
    }
  }
}
