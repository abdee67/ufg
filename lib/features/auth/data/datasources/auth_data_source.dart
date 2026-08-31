import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/features/auth/data/models/profile_model.dart';

abstract class AuthDataSource {
  Future<void> signUp(
    String email,
    String password,
    String fullName,
    String phone,
  );
  Future<Session> signIn(String email, String password);
  Future<void> sendOtp(String email);
  Future<void> verifyOTP(String email, String otp);
  Future<void> verifyPasswordResetOtp(String email, String otp);
  Future<void> signOut();
  Future<void> resetPassword(String email, String password);
  Future<void> forgotPassword(String email);
  Future<String> checkStartupSession();
  Future<ProfileModel> getCurrentProfile();
}
