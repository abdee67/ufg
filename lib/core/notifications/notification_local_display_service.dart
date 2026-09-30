import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Displays foreground FCM messages through the local notification pipeline.
///
/// Android only: the channel id MUST match the `channel_id` the Edge Function
/// worker sends (`financial_notifications` in
/// `supabase/functions/notification-push-worker/index.ts`). If the channel does
/// not exist when the push arrives, Android silently renames it to
/// "Miscellaneous" and importance is downgraded.
class NotificationLocalDisplayService {
  static const String channelId = 'financial_notifications';
  static const String channelName = 'Financial notifications';
  static const String channelDescription =
      'Unity Finance transactional and workflow alerts.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Invoked with the notification payload when the user taps a notification
  /// that was displayed locally.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  Future<void> initialize() async {
    if (_initialized) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('assets/images/logo.jpg'),
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        onNotificationTap?.call(_decodePayload(payload));
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
          ),
        );

    _initialized = true;
  }

  /// Android 13+ runtime permission for notifications.
  ///
  /// Returns true when notifications are allowed (or when the platform does
  /// not require an explicit permission).
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    bool critical = false,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!_initialized) await initialize();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: critical ? Importance.max : Importance.high,
        priority: critical ? Priority.max : Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
    );

    final notificationId = data['notification_id'] is String
        ? (data['notification_id'] as String).hashCode & 0x7fffffff
        : DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    await _plugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(data),
    );
  }

  Map<String, dynamic> _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification payload decode failed: $e');
      }
    }
    return <String, dynamic>{};
  }
}
