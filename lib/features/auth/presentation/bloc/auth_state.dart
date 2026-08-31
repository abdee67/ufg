
abstract class AuthState {}

class EmailVerificationSent extends AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAddressLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthLoggedOut extends AuthState {}

class OtpSent extends AuthState {}

class OtpVerified extends AuthState {}

class ForgotPasswordSent extends AuthState {}

class PasswordResetOtpVerified extends AuthState {}

class ResetPasswordSent extends AuthState {}

class AuthAddressAutofilled extends AuthState {
  AuthAddressAutofilled();
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}
