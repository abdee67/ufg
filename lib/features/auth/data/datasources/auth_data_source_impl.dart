import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/config/supabase_config.dart';
import 'package:ufg/core/errors/exceptions/auth_exceptions.dart';
import 'package:ufg/core/errors/failures/auth_failures.dart';
import 'package:ufg/features/auth/data/datasources/auth_data_source.dart';
import 'package:ufg/features/auth/data/models/profile_model.dart';

class AuthDataSourceImpl implements AuthDataSource {
  SupabaseClient get _client => SupabaseConfig.client;

  @override
  Future<Session> signIn(String email, String password) async {
    try {
      final result = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (result.session == null) {
        throw const AuthExceptions(
          message: 'We could not start your session. Please try again.',
        );
      }

      final user = result.user ?? _client.auth.currentUser;
      if (user == null) {
        await _signOutQuietly();
        throw const AuthExceptions(
          message: 'We could not find your account. Please try again.',
        );
      }

      return result.session!;
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<void> signUp(
    String email,
    String password,
    String fullname,
    String phone,
  ) async {
    try {
      final result = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullname, 'phone': phone},
      );
      if (result.user == null) {
        throw const AuthExceptions(
          message: 'We could not create your account. Please try again.',
        );
      }
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<void> sendOtp(String email) async {
    try {
      final result = await _client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      if (result.messageId == null) {
        throw const AuthExceptions(
          message: 'We could not send a verification code. Please try again.',
        );
      }
    } catch (_) {
      try {
        await _client.auth.signInWithOtp(
          email: email,
          shouldCreateUser: true,
        );
      } catch (error, stackTrace) {
        throw AuthErrorMapper.toException(error, stackTrace);
      }
    }
  }

  @override
  Future<void> verifyOTP(String email, String otp) async {
    try {
      final result = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );
      if (result.session == null) {
        throw const InvalidOtpException();
      }

      final verifiedUser = result.user ?? _client.auth.currentUser;
      if (verifiedUser == null) {
        throw const InvalidOtpException();
      }
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<void> verifyPasswordResetOtp(String email, String otp) async {
    try {
      final result = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );
      if (result.session == null) {
        throw const InvalidOtpException();
      }
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<void> resetPassword(String email, String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<String> checkStartupSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session != null) {
        return 'authenticated';
      }
      //check memebrship status
      
      return 'no_session';
    } catch (e) {
      if (kDebugMode) {
        developer.log("checkUserSession error: ${e.toString()}");
      }
      return 'Something went wrong. Please try again.';
    }
  }

  @override
  Future<ProfileModel> getCurrentProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const AuthExceptions(
          message: 'No authenticated user found.',
        );
      }

      // Fetch profile
      final profileResponse = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        throw const AuthExceptions(
          message: 'Profile not found. Please contact support.',
        );
      }

      // Fetch roles
      final rolesResponse = await _client
          .from('user_roles')
          .select('roles(code)')
          .eq('user_id', user.id);

      final roles = <String>[];
      for (final row in rolesResponse) {
        final roleData = row['roles'];
        if (roleData != null && roleData is Map && roleData['code'] != null) {
          roles.add(roleData['code'] as String);
        }
      }

      return ProfileModel.fromJson(
        Map<String, dynamic>.from(profileResponse),
        roles: roles,
      );
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  Future<void> _signOutQuietly() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }
}
