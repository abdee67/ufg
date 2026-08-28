import 'package:get_it/get_it.dart';
import 'package:ufg/features/auth/data/datasources/auth_data_source.dart';
import 'package:ufg/features/auth/data/datasources/auth_data_source_impl.dart';
import 'package:ufg/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ufg/features/auth/domain/repositories/auth_repository.dart';
import 'package:ufg/features/auth/domain/usecases/check_startup_session.dart';
import 'package:ufg/features/auth/domain/usecases/forgot_password.dart';
import 'package:ufg/features/auth/domain/usecases/reset_password.dart';
import 'package:ufg/features/auth/domain/usecases/send_otp.dart';
import 'package:ufg/features/auth/domain/usecases/sign_in.dart';
import 'package:ufg/features/auth/domain/usecases/sign_out.dart';
import 'package:ufg/features/auth/domain/usecases/sign_up.dart';
import 'package:ufg/features/auth/domain/usecases/verify_otp.dart';
import 'package:ufg/features/auth/domain/usecases/verify_password_reset_otp.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:ufg/features/membership/data/datasources/membership_remote_data_source.dart';
import 'package:ufg/features/membership/data/repositories/membership_repository_impl.dart';
import 'package:ufg/features/membership/domain/repositories/membership_repository.dart';
import 'package:ufg/features/membership/domain/usecases/cancel_membership_application.dart';
import 'package:ufg/features/membership/domain/usecases/get_membership_status.dart';
import 'package:ufg/features/membership/domain/usecases/submit_membership_application.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_bloc.dart';

import 'package:ufg/core/api/api_client.dart';

final getit = GetIt.instance;
void initDependency() {
  //================== Core API Client ===================
  getit.registerLazySingleton<ApiClient>(() => ApiClient());

  //================== injecting auth ===================
  getit.registerLazySingleton<AuthDataSource>(() => AuthDataSourceImpl());
  getit.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getit()),
  );

  // Auth use cases
  getit.registerLazySingleton(() => SignIn(getit()));
  getit.registerLazySingleton(() => SignUp(getit()));
  getit.registerLazySingleton(() => SignOut(getit()));
  getit.registerLazySingleton(() => SendOtp(getit()));
  getit.registerLazySingleton(() => VerifyOTP(getit()));
  getit.registerLazySingleton(() => VerifyPasswordResetOtp(getit()));
  getit.registerLazySingleton(() => CheckStartupSession(getit()));
  getit.registerLazySingleton(() => ForgotPassword(getit()));
  getit.registerLazySingleton(() => ResetPassword(getit()));

  // Auth bloc
  getit.registerFactory(
    () => AuthBloc(
      getit(),
      getit(),
      getit(),
      getit(),
      getit(),
      getit(),
      getit(),
      getit(),
      getit(),
    ),
  );

  //================== injecting membership ===================
  getit.registerLazySingleton<MembershipRemoteDataSource>(
    () => MembershipRemoteDataSourceImpl(apiClient: getit()),
  );
  getit.registerLazySingleton<MembershipRepository>(
    () => MembershipRepositoryImpl(remoteDataSource: getit()),
  );

  // Membership use cases
  getit.registerLazySingleton(() => GetMembershipStatus(getit()));
  getit.registerLazySingleton(() => SubmitMembershipApplication(getit()));
  getit.registerLazySingleton(() => CancelMembershipApplication(getit()));

  // Membership bloc
  getit.registerFactory(
    () => MembershipBloc(
      getMembershipStatus: getit(),
      submitMembershipApplication: getit(),
      cancelMembershipApplication: getit(),
    ),
  );
}

