abstract class AuthEvent {}

class SignInRequested extends AuthEvent {
  final String phone;
  final String password;

  SignInRequested(this.phone, this.password);
}

class SignUpRequested extends AuthEvent {
  final String password;
  final String fullName;
  final String phone;

  SignUpRequested({
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

class ChangePasswordRequested extends AuthEvent {
  final String password;

  ChangePasswordRequested(this.password);
}

class CheckStartupSessionRequested extends AuthEvent {}
