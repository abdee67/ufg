import 'package:get_it/get_it.dart';
import 'package:ufg/core/utils/app_state_notifier.dart';
import 'package:ufg/features/auth/data/datasources/auth_data_source.dart';
import 'package:ufg/features/auth/data/datasources/auth_data_source_impl.dart';
import 'package:ufg/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ufg/features/auth/domain/repositories/auth_repository.dart';
import 'package:ufg/features/auth/domain/usecases/check_startup_session.dart';
import 'package:ufg/features/auth/domain/usecases/forgot_password.dart';
import 'package:ufg/features/auth/domain/usecases/get_current_profile.dart';
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
import 'package:ufg/features/membership/domain/usecases/upload_fayda_document.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_bloc.dart';

import 'package:ufg/features/savings/data/datasources/savings_remote_data_source.dart';
import 'package:ufg/features/savings/data/repositories/savings_repository_impl.dart';
import 'package:ufg/features/savings/domain/repositories/savings_repository.dart';
import 'package:ufg/features/savings/domain/usecases/cancel_withdrawal_request.dart';
import 'package:ufg/features/savings/domain/usecases/get_savings_history.dart';
import 'package:ufg/features/savings/domain/usecases/get_savings_obligations.dart';
import 'package:ufg/features/savings/domain/usecases/get_savings_summary.dart';
import 'package:ufg/features/savings/domain/usecases/get_withdrawal_requests.dart';
import 'package:ufg/features/savings/domain/usecases/request_savings_withdrawal.dart';
import 'package:ufg/features/savings/domain/usecases/submit_savings_payment.dart';
import 'package:ufg/features/savings/domain/usecases/upload_payment_proof.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_bloc.dart';

import 'package:ufg/features/loans/data/datasources/loans_remote_data_source.dart';
import 'package:ufg/features/loans/data/repositories/loan_repository_impl.dart';
import 'package:ufg/features/loans/domain/repositories/loan_repository.dart';
import 'package:ufg/features/loans/domain/usecases/cancel_loan_application.dart';
import 'package:ufg/features/loans/domain/usecases/evaluate_loan_eligibility.dart';
import 'package:ufg/features/loans/domain/usecases/get_loan_application_detail.dart';
import 'package:ufg/features/loans/domain/usecases/get_loan_installments.dart';
import 'package:ufg/features/loans/domain/usecases/get_loan_products.dart';
import 'package:ufg/features/loans/domain/usecases/get_my_member_loan_limit.dart';
import 'package:ufg/features/loans/domain/usecases/search_loan_guarantors.dart';
import 'package:ufg/features/loans/domain/usecases/get_active_outsider_loan_product.dart';
import 'package:ufg/features/loans/domain/usecases/get_my_guarantor_requests.dart';
import 'package:ufg/features/loans/domain/usecases/get_my_loan_applications.dart';
import 'package:ufg/features/loans/domain/usecases/get_my_loans.dart';
import 'package:ufg/features/loans/domain/usecases/request_loan_extension.dart';
import 'package:ufg/features/loans/domain/usecases/request_loan_guarantor.dart';
import 'package:ufg/features/loans/domain/usecases/respond_to_guarantor_request.dart';
import 'package:ufg/features/loans/domain/usecases/submit_loan_application.dart';
import 'package:ufg/features/loans/domain/usecases/submit_outsider_loan_application.dart';
import 'package:ufg/features/loans/domain/usecases/submit_loan_repayment_payment.dart';
import 'package:ufg/features/loans/domain/usecases/upload_loan_payment_proof.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_bloc.dart';

final getit = GetIt.instance;

void initDependency() {
  getit.registerLazySingleton<AppStateNotifier>(() => AppStateNotifier());

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
  getit.registerLazySingleton(() => GetCurrentProfile(getit()));

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
    () => MembershipRemoteDataSourceImpl(),
  );
  getit.registerLazySingleton<MembershipRepository>(
    () => MembershipRepositoryImpl(remoteDataSource: getit()),
  );

  // Membership use cases
  getit.registerLazySingleton(() => GetMembershipStatus(getit()));
  getit.registerLazySingleton(() => SubmitMembershipApplication(getit()));
  getit.registerLazySingleton(() => CancelMembershipApplication(getit()));
  getit.registerLazySingleton(() => UploadFaydaDocument(getit()));

  // Membership bloc
  getit.registerFactory(
    () => MembershipBloc(
      getMembershipStatus: getit(),
      submitMembershipApplication: getit(),
      cancelMembershipApplication: getit(),
      uploadFaydaDocument: getit(),
    ),
  );

  //================== injecting savings ===================
  getit.registerLazySingleton<SavingsRemoteDataSource>(
    () => SavingsRemoteDataSourceImpl(),
  );
  getit.registerLazySingleton<SavingsRepository>(
    () => SavingsRepositoryImpl(remoteDataSource: getit()),
  );

  // Savings use cases
  getit.registerLazySingleton(() => GetSavingsSummary(getit()));
  getit.registerLazySingleton(() => GetSavingsObligations(getit()));
  getit.registerLazySingleton(() => GetSavingsHistory(getit()));
  getit.registerLazySingleton(() => SubmitSavingsPayment(getit()));
  getit.registerLazySingleton(() => RequestSavingsWithdrawal(getit()));
  getit.registerLazySingleton(() => CancelWithdrawalRequest(getit()));
  getit.registerLazySingleton(() => GetWithdrawalRequests(getit()));
  getit.registerLazySingleton(() => UploadPaymentProof(getit()));

  // Savings bloc
  getit.registerFactory(
    () => SavingsBloc(
      getSavingsSummary: getit(),
      getSavingsObligations: getit(),
      getSavingsHistory: getit(),
      submitSavingsPayment: getit(),
      requestSavingsWithdrawal: getit(),
      cancelWithdrawalRequest: getit(),
      getWithdrawalRequests: getit(),
      uploadPaymentProof: getit(),
    ),
  );

  //================== injecting loans ===================
  getit.registerLazySingleton<LoansRemoteDataSource>(
    () => LoansRemoteDataSourceImpl(),
  );
  getit.registerLazySingleton<LoanRepository>(
    () => LoanRepositoryImpl(remoteDataSource: getit()),
  );

  // Loan use cases
  getit.registerLazySingleton(() => GetLoanProducts(getit()));
  getit.registerLazySingleton(() => GetMyMemberLoanLimit(getit()));
  getit.registerLazySingleton(() => SearchLoanGuarantors(getit()));
  getit.registerLazySingleton(() => GetActiveOutsiderLoanProduct(getit()));
  getit.registerLazySingleton(() => GetMyLoanApplications(getit()));
  getit.registerLazySingleton(() => GetMyLoans(getit()));
  getit.registerLazySingleton(() => GetLoanApplicationDetail(getit()));
  getit.registerLazySingleton(() => SubmitLoanApplication(getit()));
  getit.registerLazySingleton(() => SubmitOutsiderLoanApplication(getit()));
  getit.registerLazySingleton(() => CancelLoanApplication(getit()));
  getit.registerLazySingleton(() => EvaluateLoanEligibility(getit()));
  getit.registerLazySingleton(() => RequestLoanGuarantor(getit()));
  getit.registerLazySingleton(() => GetMyGuarantorRequests(getit()));
  getit.registerLazySingleton(() => RespondToGuarantorRequest(getit()));
  getit.registerLazySingleton(() => RequestLoanExtension(getit()));
  getit.registerLazySingleton(() => GetLoanInstallments(getit()));
  getit.registerLazySingleton(() => SubmitLoanRepaymentPayment(getit()));
  getit.registerLazySingleton(() => UploadLoanPaymentProof(getit()));

  // Loan bloc
  getit.registerFactory(
    () => LoanBloc(
      getLoanProducts: getit(),
      getMyMemberLoanLimit: getit(),
      searchLoanGuarantors: getit(),
      getActiveOutsiderLoanProduct: getit(),
      getMyLoanApplications: getit(),
      getMyLoans: getit(),
      getLoanApplicationDetail: getit(),
      submitLoanApplication: getit(),
      submitOutsiderLoanApplication: getit(),
      cancelLoanApplication: getit(),
      evaluateLoanEligibility: getit(),
      requestLoanGuarantor: getit(),
      getMyGuarantorRequests: getit(),
      respondToGuarantorRequest: getit(),
      requestLoanExtension: getit(),
      getLoanInstallments: getit(),
      submitLoanRepaymentPayment: getit(),
      uploadLoanPaymentProof: getit(),
    ),
  );
}
