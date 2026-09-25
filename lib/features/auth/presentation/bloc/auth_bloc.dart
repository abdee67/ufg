import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ufg/features/auth/domain/usecases/check_startup_session.dart';
import 'package:ufg/features/auth/domain/usecases/change_password.dart';
import 'package:ufg/features/auth/domain/usecases/requires_password_change.dart';
import 'package:ufg/features/auth/domain/usecases/sign_in.dart';
import 'package:ufg/features/auth/domain/usecases/sign_out.dart';
import 'package:ufg/features/auth/domain/usecases/sign_up.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignOut signOut;
  final SignUp signUp;
  //  final GetCurrentLocationAddress getCurrentLocationAddress;
  // final GetCurrentCustomer getCurrentCustomer;
  // final UpdateCustomerProfile updateCustomerProfile;
  final ChangePassword changePassword;
  final RequiresPasswordChange requiresPasswordChange;
  final CheckStartupSession checkStartupSession;
  AuthBloc(
    this.signIn,
    this.signOut,
    this.signUp,
    // this.getCurrentLocationAddress,
    // this.getCurrentCustomer,
    // this.updateCustomerProfile,
    this.changePassword,
    this.requiresPasswordChange,
    this.checkStartupSession,
  ) : super(AuthInitial()) {
    on<CheckStartupSessionRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await checkStartupSession();
      result.fold((failure) => emit(AuthFailure(failure.message)), (status) {
        if (status == 'authenticated') {
          emit(AuthSuccess());
        } else if (status == 'password_change_required') {
          emit(PasswordChangeRequired());
        } else if (status == 'no_session') {
          emit(AuthLoggedOut());
        } else {
          emit(AuthFailure(status));
        }
      });
    });

    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signIn(event.phone, event.password);
      final failure = result.fold((failure) => failure, (_) => null);
      if (failure != null) {
        emit(AuthFailure(failure.message));
        return;
      }

      final required = await requiresPasswordChange();
      required.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (isRequired) =>
            emit(isRequired ? PasswordChangeRequired() : AuthSuccess()),
      );
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signUp(event.password, event.fullName, event.phone);
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(AuthSuccess()),
      );
    });
    on<SignOutRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signOut();
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(AuthLoggedOut()),
      );
    });
    on<ChangePasswordRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await changePassword(event.password);
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(PasswordChanged()),
      );
    });
  }
}
