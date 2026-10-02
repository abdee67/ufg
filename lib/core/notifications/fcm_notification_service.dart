import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:ufg/core/notifications/notification_local_display_service.dart';
import 'package:ufg/core/notifications/notification_navigation_service.dart';
import 'package:ufg/features/notifications/domain/usecases/deactivate_notification_device.dart';
import 'package:ufg/features/notifications/domain/usecases/register_notification_device.dart';

/// Background message handler.
///
/// Must be a top-level function annotated with `vm:entry-point`. Keep it very
/// small: notification-carrying messages are rendered by the OS while the app
/// is backgrounded, and financial synchronization never belongs here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Unity Finance background FCM message: ${message.messageId}');
}

/// Owns the FCM lifecycle: permission, token registration/refresh, foreground
/// display, tap routing and logout deactivation.
///
/// Push is optional. Declining the OS permission never blocks login; the
/// durable in-app inbox keeps working.
class FcmNotificationService {
  final RegisterNotificationDevice registerNotificationDevice;
  final DeactivateNotificationDevice deactivateNotificationDevice;
  final NotificationLocalDisplayService localDisplay;
  final NotificationNavigationService navigation;

  FcmNotificationService({
    required this.registerNotificationDevice,
    required this.deactivateNotificationDevice,
    required this.localDisplay,
    required this.navigation,
  });

  bool _firebaseReady = false;
  bool _initialized = false;
  bool _deviceRegistered = false;
  String? _currentToken;

  bool get isSupported => defaultTargetPlatform == TargetPlatform.android;

  /// True once `register_notification_device_v1` succeeded for this process.
  bool get isDeviceRegistered => _deviceRegistered;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!isSupported) return;

    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase init skipped: $e');
      }
      return;
    }

    await localDisplay.initialize();
    localDisplay.onNotificationTap = navigation.handleNotificationData;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => navigation.handleNotificationData(message.data),
    );

    // Terminated-state tap. The router is created asynchronously in main, so
    // NotificationNavigationService buffers this until the router is attached.
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        navigation.handleNotificationData(initialMessage.data);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getInitialMessage failed: $e');
      }
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // iOS only; ignored on Android.
    }

    _initialized = true;
  }

  /// Call once the session is authenticated (login success or restored
  /// session). Safe to call repeatedly: registration is idempotent and a
  /// successful registration short-circuits.
  ///
  /// Transient failures (cold-start Firebase, `getToken()` SERVICE_NOT_AVAILABLE,
  /// flaky network) are retried with backoff, because otherwise the device
  /// silently loses push for the whole session and only the durable in-app
  /// inbox keeps working.
  Future<void> syncDeviceRegistration() async {
    if (!_firebaseReady || !isSupported) return;
    if (_deviceRegistered) return;

    const retryDelays = [
      Duration(seconds: 15),
      Duration(seconds: 45),
      Duration(minutes: 2),
    ];

    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      if (await _tryRegisterDevice()) {
        _deviceRegistered = true;
        return;
      }

      if (attempt < retryDelays.length) {
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }

    if (kDebugMode) {
      debugPrint(
        'Notification device registration failed after retries. Push stays '
        'disabled for this session; the in-app inbox is unaffected. It also '
        'retries on the next app resume.',
      );
    }
  }

  Future<bool> _tryRegisterDevice() async {
    try {
      await _requestPermissions();

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return false;

      return await _registerToken(token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Device registration attempt failed: $e');
      }
      return false;
    }
  }

  /// Must run BEFORE the session is destroyed, while the JWT is still valid.
  Future<void> deactivateCurrentDevice() async {
    if (!_firebaseReady || !isSupported) return;

    try {
      final token =
          _currentToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await deactivateNotificationDevice(token);
      _currentToken = null;
      _deviceRegistered = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Device deactivation failed: $e');
      }
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final body = message.notification?.body ?? '';
    if (body.isEmpty) return;

    final data = Map<String, dynamic>.from(message.data);
    final title = message.notification?.title ?? 'Unity Finance';

    await localDisplay.showNotification(
      title: title,
      body: body,
      data: data,
      critical: data['priority'] == 'critical',
    );
  }

  Future<void> _requestPermissions() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied &&
          kDebugMode) {
        debugPrint('User declined FCM authorization; in-app inbox continues.');
      }
      await localDisplay.requestPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Permission request failed: $e');
      }
    }
  }

  Future<bool> _registerToken(String token) async {
    _currentToken = token;

    final result = await registerNotificationDevice(
      fcmToken: token,
      platform: _platformName,
      appType: 'member',
      locale: ui.PlatformDispatcher.instance.locale.toString(),
    );

    return result.fold(
      (failure) {
        if (kDebugMode) {
          debugPrint(
            'register_notification_device_v1 failed: ${failure.message}',
          );
        }
        return false;
      },
      (deviceId) {
        if (kDebugMode) {
          debugPrint('Notification device registered: $deviceId');
        }
        return true;
      },
    );
  }

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }
}
