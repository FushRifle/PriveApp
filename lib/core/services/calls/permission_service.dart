import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      return true;
    }

    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final grantedCamera = statuses[Permission.camera]?.isGranted ?? false;
    final grantedMicrophone =
        statuses[Permission.microphone]?.isGranted ?? false;

    return grantedCamera && grantedMicrophone;
  }

  static Future<bool> checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    return cameraStatus.isGranted && microphoneStatus.isGranted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }

  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
