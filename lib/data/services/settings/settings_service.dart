import 'package:dio/dio.dart';
import '../../../core/api_service.dart';

class SettingsService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _api.get('/api/settings');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to get settings';
    }
  }

  Future<Map<String, dynamic>> updateSettings({
    bool? notificationsEnabled,
    bool? privateAccount,
    bool? twoFactorAuth,
    String? language,
    String? videoQuality,
    String? theme,
    bool? autoPlayVideos,
    bool? saveOriginalPhotos,
    bool? showActivityStatus,
    bool? allowTagging,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (notificationsEnabled != null) {
        data['notificationsEnabled'] = notificationsEnabled;
      }
      if (privateAccount != null) data['privateAccount'] = privateAccount;
      if (twoFactorAuth != null) data['twoFactorAuth'] = twoFactorAuth;
      if (language != null) data['language'] = language;
      if (videoQuality != null) data['videoQuality'] = videoQuality;
      if (theme != null) data['theme'] = theme;
      if (autoPlayVideos != null) data['autoPlayVideos'] = autoPlayVideos;
      if (saveOriginalPhotos != null) {
        data['saveOriginalPhotos'] = saveOriginalPhotos;
      }
      if (showActivityStatus != null) {
        data['showActivityStatus'] = showActivityStatus;
      }
      if (allowTagging != null) data['allowTagging'] = allowTagging;

      final response = await _api.put('/api/settings', data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to update settings';
    }
  }

  Future<void> deleteSettings() async {
    try {
      await _api.delete('/api/settings');
    } on DioException catch (e) {
      throw e.response?.data['error'] ?? 'Failed to delete settings';
    }
  }
}
