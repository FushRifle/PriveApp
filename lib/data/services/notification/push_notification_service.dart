import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../firebase_options.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}
}

class PushNotificationService with WidgetsBindingObserver {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final NotificationService _notificationService = NotificationService();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;

  bool _initialized = false;
  bool _firebaseReady = false;
  String? _registeredToken;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (kIsWeb) {
      return;
    }

    WidgetsBinding.instance.addObserver(this);

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firebaseReady = true;
    } catch (error) {
      debugPrint('Push notifications disabled: $error');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _openedMessageSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
  }

  Future<void> syncDeviceToken() async {
    await initialize();
    if (!_firebaseReady) {
      return;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }

    await _registerToken(token);

    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _registerToken(token);
    });
  }

  Future<void> deleteDeviceToken() async {
    if (_registeredToken == null || _registeredToken!.trim().isEmpty) {
      return;
    }

    final token = _registeredToken!;
    _registeredToken = null;

    try {
      await _notificationService.deleteDeviceToken(token);
    } catch (error) {
      debugPrint('Failed to delete push token: $error');
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _openedMessageSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription = null;
    _openedMessageSubscription = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncDeviceToken();
    }
  }

  Future<void> _registerToken(String token) async {
    if (_registeredToken == token) {
      return;
    }

    try {
      await _notificationService.registerDeviceToken(
        token: token,
        platform: _platformName,
      );
      _registeredToken = token;
    } catch (error) {
      debugPrint('Failed to register push token: $error');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground push received: ${message.messageId}');
  }

  void _handleOpenedMessage(RemoteMessage message) {
    debugPrint('Push opened: ${message.messageId}');
  }

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'unknown';
    }
  }
}
