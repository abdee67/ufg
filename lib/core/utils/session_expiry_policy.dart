import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/constants/session_constants.dart';

/// Client-side session expiry utility for Unity Finance.
///
/// This is a **pure utility** — it reads/writes timestamps and signs out
/// locally when the 1-hour inactivity threshold is exceeded. It does
/// NOT perform navigation or call domain use-cases; those responsibilities
/// belong to the BLoC / presentation layer.
class SessionExpiryPolicy {
  SessionExpiryPolicy._();

  // ─── Activity tracking ────────────────────────────────────────────

  /// Records the latest active interaction in the app.
  static Future<void> recordActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        SessionConstants.lastActiveAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// Records the moment the app went to the background.
  static Future<void> markBackgrounded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(SessionConstants.backgroundedAtKey, nowMs);
      await prefs.setInt(SessionConstants.lastActiveAtKey, nowMs);
    } catch (_) {}
  }

  // ─── Expiry evaluation ────────────────────────────────────────────

  /// Returns `true` when 1 hour or more has passed since the user was
  /// last active or when the app went to the background.
  static Future<bool> isSessionExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      final bgMs = prefs.getInt(SessionConstants.backgroundedAtKey);
      if (bgMs != null) {
        final bgElapsed =
            now.difference(DateTime.fromMillisecondsSinceEpoch(bgMs));
        if (bgElapsed >= SessionConstants.maxInactivityDuration) return true;
      }

      final activeMs = prefs.getInt(SessionConstants.lastActiveAtKey);
      if (activeMs != null) {
        final activeElapsed =
            now.difference(DateTime.fromMillisecondsSinceEpoch(activeMs));
        if (activeElapsed >= SessionConstants.maxInactivityDuration) return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Enforcement ──────────────────────────────────────────────────

  /// Checks and enforces the 1-hour expiry. If expired and a local
  /// Supabase session exists, it signs out locally and flags a notice
  /// for the login screen.
  ///
  /// Returns `true` when an active session was invalidated.
  static Future<bool> checkAndEnforceExpiry() async {
    try {
      final expired = await isSessionExpired();
      if (!expired) {
        await recordActivity();
        return false;
      }

      final auth = Supabase.instance.client.auth;
      final hadSession = auth.currentSession != null;

      if (hadSession) {
        await _flagExpiredNotice();
        try {
          await auth.signOut(scope: SignOutScope.local);
        } catch (e) {
          if (kDebugMode) debugPrint('Local sign out error: $e');
        }
      }

      await clear();
      return hadSession;
    } catch (e) {
      if (kDebugMode) debugPrint('Session expiry check error: $e');
      return false;
    }
  }

  // ─── Expired-session notice (consumed by LoginScreen) ─────────────

  static Future<void> _flagExpiredNotice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SessionConstants.expiredNoticeKey, true);
  }

  /// Returns and clears the one-shot notice flag. The login screen calls
  /// this once on mount to decide whether to show the expiry banner.
  static Future<bool> consumeExpiredNotice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final had = prefs.getBool(SessionConstants.expiredNoticeKey) ?? false;
      if (had) await prefs.remove(SessionConstants.expiredNoticeKey);
      return had;
    } catch (_) {
      return false;
    }
  }

  // ─── Cleanup ──────────────────────────────────────────────────────

  /// Clears stored activity and background timestamps.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(SessionConstants.backgroundedAtKey);
      await prefs.remove(SessionConstants.lastActiveAtKey);
    } catch (_) {}
  }
}
