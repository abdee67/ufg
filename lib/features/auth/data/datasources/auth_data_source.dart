import 'package:supabase_flutter/supabase_flutter.dart';

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
 // Future<CustomerModel> getCurrentCustomer();
  Future<void> signOut();
 // Future<CustomerModel> updateCustomerProfile(CustomerModel client);
  Future<void> resetPassword(String email, String password);
  Future<void> forgotPassword(String email);
  Future<String> checkStartupSession();
}
