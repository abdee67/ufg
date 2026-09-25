import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/features/auth/data/models/profile_model.dart';

abstract class AuthDataSource {
  Future<void> signUp(String password, String fullName, String phone);
  Future<Session> signIn(String phone, String password);
  Future<void> signOut();
  Future<void> changePassword(String password);
  Future<bool> requiresPasswordChange();
  Future<String> checkStartupSession();
  Future<ProfileModel> getCurrentProfile();
}
