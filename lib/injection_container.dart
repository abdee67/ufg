import 'package:get_it/get_it.dart';
import 'package:ufg/features/auth/data/datasources/auth_data_source.dart';
import 'package:ufg/features/auth/data/datasources/auth_location_data_source.dart';
import 'package:ufg/features/auth/data/datasources/auth_location_data_source_impl.dart';
import 'package:ufg/features/auth/data/datasources/auth_data_source_impl.dart';
import 'package:ufg/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ufg/features/auth/domain/repositories/auth_repository.dart';
import 'package:ufg/features/auth/domain/usecases/check_startup_session.dart';
import 'package:ufg/features/auth/domain/usecases/forgot_password.dart';
import 'package:ufg/features/auth/domain/usecases/get_current_location_address.dart'
    as auth_usecases;
import 'package:ufg/features/auth/domain/usecases/get_current_client.dart';
import 'package:ufg/features/auth/domain/usecases/create_customer_address.dart';
import 'package:ufg/features/auth/domain/usecases/reset_password.dart';
import 'package:ufg/features/auth/domain/usecases/send_otp.dart';
import 'package:ufg/features/auth/domain/usecases/sign_in.dart';
import 'package:ufg/features/auth/domain/usecases/sign_out.dart';
import 'package:ufg/features/auth/domain/usecases/sign_up.dart';
import 'package:ufg/features/auth/domain/usecases/update_client_profile.dart';
import 'package:ufg/features/auth/domain/usecases/verify_otp.dart';
import 'package:ufg/features/auth/domain/usecases/verify_password_reset_otp.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/home/presentation/bloc/home_bloc.dart';

final getit = GetIt.instance;
void initDependency() {
  //==================injecting auth data source===================
  getit.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(),
  );
  getit.registerLazySingleton<AuthLocationDataSource>(
    () => AuthLocationDataSourceImpl(),
  );

  //================== injecting  repository===================
  getit.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getit(), getit()),
  );

  // ===============injectin use case=================
  // Auth use cases
  getit.registerLazySingleton(() => SignIn(getit()));
  getit.registerLazySingleton(() => SignUp(getit()));
  getit.registerLazySingleton(() => SignOut(getit()));
  getit.registerLazySingleton(() => SendOtp(getit()));
  getit.registerLazySingleton(() => VerifyOTP(getit()));
  getit.registerLazySingleton(() => VerifyPasswordResetOtp(getit()));
  getit.registerLazySingleton(
    () => auth_usecases.GetCurrentLocationAddress(getit()),
  );
  getit.registerLazySingleton(() => CheckStartupSession(getit()));

  getit.registerLazySingleton(() => ForgotPassword(getit()));
  getit.registerLazySingleton(() => ResetPassword(getit()));
  getit.registerLazySingleton(() => GetCurrentCustomer(getit()));
  getit.registerLazySingleton(() => CreateCustomerAddress(getit()));
  getit.registerLazySingleton(() => UpdateCustomerProfile(getit()));

  // ===========injectin bloc=================
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
      getit(),
      getit(),
      getit(),
    ),
  );
  getit.registerFactory(
    () =>
        HomeBloc(getDeals: getit(), getStylists: getit(), getServices: getit()),
  );
}
