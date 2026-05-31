import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
    apiKey: 'AIzaSyDbXPeC_w3u4A4d-P45jH6HJcv7n_FHHlI',
    appId: '1:944145963099:android:4ea14d65cc89fe1e51477e',
    messagingSenderId: '944145963099',
    projectId: 'clique-1c416',
    storageBucket: 'clique-1c416.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCkjEWZUoQgPmZtWKfxDl7o5EYRLQTbSV8',
    appId: '1:944145963099:ios:114c97aa57876c7e51477e',
    messagingSenderId: '944145963099',
    projectId: 'clique-1c416',
    storageBucket: 'clique-1c416.firebasestorage.app',
    iosBundleId: 'com.fushinc.clique',
  );
}
