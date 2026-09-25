abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAddressLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthLoggedOut extends AuthState {}

class PasswordChangeRequired extends AuthState {}

class PasswordChanged extends AuthState {}

class AuthAddressAutofilled extends AuthState {
  AuthAddressAutofilled();
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}
