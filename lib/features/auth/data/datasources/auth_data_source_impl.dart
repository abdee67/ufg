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
  Future<Session> signIn(String phone, String password) async {
    try {
      final result = await _client.auth.signInWithPassword(
        phone: phone,
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
  Future<void> signUp(String password, String fullname, String phone) async {
    try {
      final result = await _client.auth.signUp(
        phone: phone,
        password: password,
        data: {'full_name': fullname, 'phone': phone},
      );
      if (result.user == null) {
        throw const AuthExceptions(
          message: 'We could not create your account. Please try again.',
        );
      }
      if (result.session == null) {
        throw const AuthExceptions(
          message:
              'Your account was created, but a session could not be started. Please contact support.',
        );
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
  Future<void> changePassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<bool> requiresPasswordChange() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const AuthExceptions(message: 'No authenticated user found.');
      }
      final profile = await _client
          .from('profiles')
          .select('must_change_password')
          .eq('id', user.id)
          .maybeSingle();
      if (profile == null) {
        throw const AuthExceptions(
          message: 'Profile not found. Please contact support.',
        );
      }
      return profile['must_change_password'] == true;
    } catch (error, stackTrace) {
      throw AuthErrorMapper.toException(error, stackTrace);
    }
  }

  @override
  Future<String> checkStartupSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session != null) {
        if (await requiresPasswordChange()) return 'password_change_required';
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
        throw const AuthExceptions(message: 'No authenticated user found.');
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
