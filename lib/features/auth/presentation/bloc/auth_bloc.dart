import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ufg/features/auth/domain/usecases/check_startup_session.dart';
import 'package:ufg/features/auth/domain/usecases/forgot_password.dart';
import 'package:ufg/features/auth/domain/usecases/reset_password.dart';
import 'package:ufg/features/auth/domain/usecases/send_otp.dart';
import 'package:ufg/features/auth/domain/usecases/sign_in.dart';
import 'package:ufg/features/auth/domain/usecases/sign_out.dart';
import 'package:ufg/features/auth/domain/usecases/sign_up.dart';
import 'package:ufg/features/auth/domain/usecases/verify_otp.dart';
import 'package:ufg/features/auth/domain/usecases/verify_password_reset_otp.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignOut signOut;
  final SignUp signUp;
  final SendOtp sendOtp;
  final VerifyOTP verifyOTP;
  final VerifyPasswordResetOtp verifyPasswordResetOtp;
  //  final GetCurrentLocationAddress getCurrentLocationAddress;
  // final GetCurrentCustomer getCurrentCustomer;
  // final UpdateCustomerProfile updateCustomerProfile;
  final ForgotPassword forgotPassword;
  final ResetPassword resetPassword;
  final CheckStartupSession checkStartupSession;
  AuthBloc(
    this.signIn,
    this.signOut,
    this.signUp,
    this.sendOtp,
    this.verifyOTP,
    this.verifyPasswordResetOtp,
    // this.getCurrentLocationAddress,
    // this.getCurrentCustomer,
    // this.updateCustomerProfile,
    this.forgotPassword,
    this.resetPassword,
    this.checkStartupSession,
  ) : super(AuthInitial()) {
    on<CheckStartupSessionRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await checkStartupSession();
      result.fold((failure) => emit(AuthFailure(failure.message)), (status) {
        if (status == 'success') {
          emit(AuthSuccess());
        } else if (status == 'no_session') {
          emit(AuthLoggedOut());
        } else {
          emit(AuthFailure(status));
        }
      });
    });

    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signIn(event.email, event.password);
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(AuthSuccess()),
      );
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signUp(
        event.email,
        event.password,
        event.fullName,
        event.phone,
      );
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(EmailVerificationSent()),
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
    on<SendOtpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await sendOtp(event.email);
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(OtpSent()),
      );
    });

    on<VerifyOtpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await verifyOTP(event.email, event.otp);
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(OtpVerified()),
      );
    });
    on<ForgotPasswordRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await forgotPassword(event.email);
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(ForgotPasswordSent()),
      );
    });
    on<VerifyPasswordResetOtpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await verifyPasswordResetOtp(event.email, event.otp);
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(PasswordResetOtpVerified()),
      );
    });
    on<ResetPasswordRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await resetPassword(event.email, event.password);
      result.fold(
        (failure) => emit(AuthFailure(failure.message)),
        (_) => emit(ResetPasswordSent()),
      );
    });
  }
}
