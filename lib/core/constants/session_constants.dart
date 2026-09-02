/// Session and security policy constants used across the application.
///
/// Centralises all session-related configuration so that domain rules
/// are defined in one place and UI / data layers simply reference them.
class SessionConstants {
  SessionConstants._();

  /// Maximum duration the app may remain backgrounded or inactive before
  /// the local session is invalidated and the user must re-authenticate.
  static const Duration maxInactivityDuration = Duration(hours: 1);

  /// SharedPreferences key: milliseconds since epoch when the app was
  /// last active in the foreground.
  static const String lastActiveAtKey = 'session_last_active_at_ms';

  /// SharedPreferences key: milliseconds since epoch when the app
  /// transitioned to a background lifecycle state.
  static const String backgroundedAtKey = 'session_backgrounded_at_ms';

  /// SharedPreferences key: boolean flag indicating that a session was
  /// forcibly expired and the login screen should show a notice.
  static const String expiredNoticeKey = 'session_expired_notice_flag';

  /// User-facing message displayed on the login screen after an automatic
  /// session expiry.
  static const String expiredNoticeMessage =
      'Your session expired due to 1 hour of inactivity. Please sign in again.';
}
