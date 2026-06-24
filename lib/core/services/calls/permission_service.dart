import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPermissions({required bool video}) async {
    final microphoneStatus = await Permission.microphone.status;
    final cameraStatus = video ? await Permission.camera.status : null;

    if (microphoneStatus.isGranted && (!video || cameraStatus!.isGranted)) {
      return true;
    }

    final statuses = await <Permission>[
      Permission.microphone,
      if (video) Permission.camera,
    ].request();

    final grantedMicrophone =
        statuses[Permission.microphone]?.isGranted ?? false;
    final grantedCamera =
        !video || (statuses[Permission.camera]?.isGranted ?? false);

    return grantedCamera && grantedMicrophone;
  }

  static Future<bool> checkPermissions({required bool video}) async {
    final microphoneStatus = await Permission.microphone.status;
    if (!video) return microphoneStatus.isGranted;
    final cameraStatus = await Permission.camera.status;

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
