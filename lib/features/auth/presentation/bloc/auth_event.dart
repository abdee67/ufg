abstract class AuthEvent {}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  SignInRequested(this.email, this.password);
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phone;

  SignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
  });
}

class SignOutRequested extends AuthEvent {
  SignOutRequested();
}

class AutoFillCurrentLocationAddressRequested extends AuthEvent {
  AutoFillCurrentLocationAddressRequested();
}

class SendOtpRequested extends AuthEvent {
  final String email;

  SendOtpRequested(this.email);
}

class VerifyOtpRequested extends AuthEvent {
  final String email;
  final String otp;

  VerifyOtpRequested(this.email, this.otp);
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;

  ForgotPasswordRequested(this.email);
}

class VerifyPasswordResetOtpRequested extends AuthEvent {
  final String email;
  final String otp;

  VerifyPasswordResetOtpRequested(this.email, this.otp);
}

class ResetPasswordRequested extends AuthEvent {
  final String email;
  final String password;

  ResetPasswordRequested(this.email, this.password);
}

class CheckStartupSessionRequested extends AuthEvent {}
