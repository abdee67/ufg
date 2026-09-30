import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/config/supabase_config.dart';
import 'package:ufg/core/errors/exceptions/auth_exceptions.dart';
import 'package:ufg/features/notifications/data/models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({
    required int limit,
    DateTime? beforeCreatedAt,
    String? beforeId,
  });

  Future<int> getUnreadCount();

  Future<bool> markNotificationRead(String notificationId);

  Future<int> markAllNotificationsRead();

  Future<String> registerNotificationDevice({
    required String fcmToken,
    required String platform,
    required String appType,
    String? deviceIdentifier,
    String? appVersion,
    String? appBuild,
    String? locale,
    String? timezone,
  });

  Future<bool> deactivateNotificationDevice(String fcmToken);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  SupabaseClient get _client => SupabaseConfig.client;

  String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthExceptions(message: 'Not authenticated.');
    }
    return user.id;
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    required int limit,
    DateTime? beforeCreatedAt,
    String? beforeId,
  }) async {
    try {
      _currentUserId;

      final response = await _client.rpc(
        'list_my_notifications_v1',
        params: {
          'p_limit': limit,
          'p_before_created_at': beforeCreatedAt?.toUtc().toIso8601String(),
          'p_before_id': beforeId,
        },
      );

      if (response == null) return [];
      final list = response as List;
      return list
          .map((item) =>
              NotificationModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC list_my_notifications_v1 error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      _currentUserId;
      final response =
          await _client.rpc('get_my_unread_notification_count_v1');
      if (response == null) return 0;
      return (response as num).toInt();
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC get_my_unread_notification_count_v1 error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<bool> markNotificationRead(String notificationId) async {
    try {
      _currentUserId;
      final response = await _client.rpc(
        'mark_notification_read_v1',
        params: {'p_notification_id': notificationId},
      );
      return response == true;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC mark_notification_read_v1 error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<int> markAllNotificationsRead() async {
    try {
      _currentUserId;
      final response = await _client.rpc('mark_all_notifications_read_v1');
      if (response == null) return 0;
      return (response as num).toInt();
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC mark_all_notifications_read_v1 error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<String> registerNotificationDevice({
    required String fcmToken,
    required String platform,
    required String appType,
    String? deviceIdentifier,
    String? appVersion,
    String? appBuild,
    String? locale,
    String? timezone,
  }) async {
    try {
      _currentUserId;
      final response = await _client.rpc(
        'register_notification_device_v1',
        params: {
          'p_fcm_token': fcmToken,
          'p_platform': platform,
          'p_app_type': appType,
          'p_device_identifier': deviceIdentifier,
          'p_app_version': appVersion,
          'p_app_build': appBuild,
          'p_locale': locale,
          'p_timezone': timezone,
        },
      );

      if (response == null) {
        throw const AuthExceptions(
          message: 'Failed to register this device for notifications.',
        );
      }
      return response as String;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC register_notification_device_v1 error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }

  @override
  Future<bool> deactivateNotificationDevice(String fcmToken) async {
    try {
      _currentUserId;
      final response = await _client.rpc(
        'deactivate_notification_device_v1',
        params: {'p_fcm_token': fcmToken},
      );
      return response == true;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('RPC deactivate_notification_device_v1 error: ${e.message}');
      }
      throw AuthExceptions(message: e.message);
    } catch (e) {
      if (e is AuthExceptions) rethrow;
      throw AuthExceptions(message: e.toString());
    }
  }
}
