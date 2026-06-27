import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:clique/app/configs/api_config.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web options are not configured.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: ApiConfig.firebaseAndroidApiKey,
    appId: ApiConfig.firebaseAndroidAppId,
    messagingSenderId: ApiConfig.firebaseMessagingSenderId,
    projectId: ApiConfig.firebaseProjectId,
    storageBucket: ApiConfig.firebaseStorageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: ApiConfig.firebaseIosApiKey,
    appId: ApiConfig.firebaseIosAppId,
    messagingSenderId: ApiConfig.firebaseMessagingSenderId,
    projectId: ApiConfig.firebaseProjectId,
    storageBucket: ApiConfig.firebaseStorageBucket,
    iosBundleId: ApiConfig.firebaseIosBundleId,
  );
}
