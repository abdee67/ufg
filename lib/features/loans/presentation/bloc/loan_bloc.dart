import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ufg/features/loans/data/models/guarantor_request_model.dart';
import 'package:ufg/features/loans/data/models/loan_application_model.dart';
import 'package:ufg/features/loans/data/models/loan_eligibility_result_model.dart';
import 'package:ufg/features/loans/domain/usecases/cancel_loan_application.dart';
import 'package:ufg/features/loans/domain/usecases/evaluate_loan_eligibility.dart';
import 'package:ufg/features/loans/domain/usecases/get_loan_application_detail.dart';
import 'package:ufg/features/loans/domain/usecases/get_loan_installments.dart';
import 'package:ufg/features/loans/domain/usecases/get_loan_products.dart';
import 'package:ufg/features/loans/domain/usecases/get_my_guarantor_requests.dart';
import 'package:ufg/features/loans/domain/usecases/get_my_loan_applications.dart';
import 'package:ufg/features/loans/domain/usecases/get_my_loans.dart';
import 'package:ufg/features/loans/domain/usecases/request_loan_extension.dart';
import 'package:ufg/features/loans/domain/usecases/request_loan_guarantor.dart';
import 'package:ufg/features/loans/domain/usecases/respond_to_guarantor_request.dart';
import 'package:ufg/features/loans/domain/usecases/submit_loan_application.dart';
import 'package:ufg/features/loans/domain/usecases/submit_loan_repayment_payment.dart';
import 'package:ufg/features/loans/domain/usecases/upload_loan_payment_proof.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_event.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_state.dart';

class LoanBloc extends Bloc<LoanEvent, LoanState> {
  final GetLoanProducts getLoanProducts;
  final GetMyLoanApplications getMyLoanApplications;
  final GetMyLoans getMyLoans;
  final GetLoanApplicationDetail getLoanApplicationDetail;
  final SubmitLoanApplication submitLoanApplication;
  final CancelLoanApplication cancelLoanApplication;
  final EvaluateLoanEligibility evaluateLoanEligibility;
  final RequestLoanGuarantor requestLoanGuarantor;
  final GetMyGuarantorRequests getMyGuarantorRequests;
  final RespondToGuarantorRequest respondToGuarantorRequest;
  final RequestLoanExtension requestLoanExtension;
  final GetLoanInstallments getLoanInstallments;
  final SubmitLoanRepaymentPayment submitLoanRepaymentPayment;
  final UploadLoanPaymentProof uploadLoanPaymentProof;

  LoanBloc({
    required this.getLoanProducts,
    required this.getMyLoanApplications,
    required this.getMyLoans,
    required this.getLoanApplicationDetail,
    required this.submitLoanApplication,
    required this.cancelLoanApplication,
    required this.evaluateLoanEligibility,
    required this.requestLoanGuarantor,
    required this.getMyGuarantorRequests,
    required this.respondToGuarantorRequest,
    required this.requestLoanExtension,
    required this.getLoanInstallments,
    required this.submitLoanRepaymentPayment,
    required this.uploadLoanPaymentProof,
  }) : super(LoanInitial()) {
    on<LoadLoansDashboardRequested>(_onLoadLoansDashboard);
    on<LoadLoanProductsRequested>(_onLoadLoanProducts);
    on<SubmitLoanApplicationRequested>(_onSubmitLoanApplication);
    on<CancelLoanApplicationRequested>(_onCancelLoanApplication);
    on<LoadLoanApplicationDetailRequested>(_onLoadLoanApplicationDetail);
    on<EvaluateLoanEligibilityRequested>(_onEvaluateLoanEligibility);
    on<RequestLoanGuarantorRequested>(_onRequestLoanGuarantor);
    on<LoadGuarantorRequestsRequested>(_onLoadGuarantorRequests);
    on<RespondToGuarantorRequestEvent>(_onRespondToGuarantorRequest);
    on<LoadLoanDetailsRequested>(_onLoadLoanDetails);
    on<RequestLoanExtensionRequested>(_onRequestLoanExtension);
    on<SubmitLoanRepaymentRequested>(_onSubmitLoanRepayment);
  }

  Future<void> _onLoadLoansDashboard(
    LoadLoansDashboardRequested event,
    Emitter<LoanState> emit,
  ) async {
    emit(LoanLoading());

    final loansResult = await getMyLoans();
    final appsResult = await getMyLoanApplications();
    final productsResult = await getLoanProducts();
    final guarantorResult = await getMyGuarantorRequests();

    if (loansResult.isLeft()) {
      emit(LoanFailure(message: loansResult.fold((l) => l.message, (_) => '')));
      return;
    }
    if (appsResult.isLeft()) {
      emit(LoanFailure(message: appsResult.fold((l) => l.message, (_) => '')));
      return;
    }
    if (productsResult.isLeft()) {
      emit(LoanFailure(message: productsResult.fold((l) => l.message, (_) => '')));
      return;
    }

    final activeLoans = loansResult.getOrElse(() => []);
    final apps = appsResult.getOrElse(() => []);
    final products = productsResult.getOrElse(() => []);
    final guarantorReqs = guarantorResult.getOrElse(() => []);
    final pendingGuarantorReqs = guarantorReqs.where((g) => g.isPending).toList();

    emit(
      LoansDashboardLoaded(
        activeLoans: activeLoans,
        applications: apps,
        products: products,
        pendingGuarantorRequests: pendingGuarantorReqs,
      ),
    );
  }

  Future<void> _onLoadLoanProducts(
    LoadLoanProductsRequested event,
    Emitter<LoanState> emit,
  ) async {
    emit(LoanLoading());
    final result = await getLoanProducts();
    result.fold(
      (failure) => emit(LoanFailure(message: failure.message)),
      (products) => emit(LoanProductsLoaded(products)),
    );
  }

  Future<void> _onSubmitLoanApplication(
    SubmitLoanApplicationRequested event,
    Emitter<LoanState> emit,
  ) async {
    emit(const LoanActionInProgress(message: 'Submitting loan application...'));

    final result = await submitLoanApplication(
      loanProductId: event.loanProductId,
      requestedAmount: event.requestedAmount,
      purpose: event.purpose,
    );

    await result.fold(
      (failure) async => emit(LoanFailure(message: failure.message)),
      (response) async {
        final applicationId = response['application_id'] as String?;
        if (event.guarantorMemberId != null &&
            event.guarantorMemberId!.isNotEmpty &&
            applicationId != null) {
          emit(const LoanActionInProgress(message: 'Requesting guarantor approval...'));
          await requestLoanGuarantor(
            loanApplicationId: applicationId,
            guarantorMemberId: event.guarantorMemberId!,
          );
        }

        emit(
          LoanActionSuccess(
            message: 'Loan application submitted successfully!',
            data: response,
          ),
        );
      },
    );
  }

  Future<void> _onCancelLoanApplication(
    CancelLoanApplicationRequested event,
    Emitter<LoanState> emit,
  ) async {
    emit(const LoanActionInProgress(message: 'Cancelling application...'));
    final result = await cancelLoanApplication(event.applicationId);
    result.fold(
      (failure) => emit(LoanFailure(message: failure.message)),
      (_) => emit(const LoanActionSuccess(message: 'Loan application cancelled.')),
    );
  }

  Future<void> _onLoadLoanApplicationDetail(
    LoadLoanApplicationDetailRequested event,
    Emitter<LoanState> emit,
  ) async {
    emit(LoanLoading());
    final result = await getLoanApplicationDetail(event.applicationId);

    result.fold(
      (failure) => emit(LoanFailure(message: failure.message)),
      (data) {
        final appModel = LoanApplicationModel.fromJson(data);
        LoanEligibilityResultModel? eligibility;
        if (data['eligibility_checks'] != null) {
          eligibility = LoanEligibilityResultModel.fromJson({
            'eligible': data['eligibility_status'] == 'eligible',
            'checks': data['eligibility_checks'],
          });
        }
        GuarantorRequestModel? guarantor;
        if (data['guarantor'] != null && data['guarantor'] is Map && (data['guarantor'] as Map).isNotEmpty) {
          guarantor = GuarantorRequestModel.fromJson(Map<String, dynamic>.from(data['guarantor'] as Map));
        }

        emit(
          LoanApplicationDetailLoaded(
            application: appModel,
            eligibility: eligibility,
            guarantor: guarantor,
          ),
        );
      },
    );
  }

  Future<void> _onEvaluateLoanEligibility(
    EvaluateLoanEligibilityRequested event,
    Emitter<LoanState> emit,
  ) async {
    emit(const LoanActionInProgress(message: 'Evaluating eligibility...'));
    final result = await evaluateLoanEligibility(event.applicationId);
    result.fold(
      (failure) => emit(LoanFailure(message: failure.message)),
      (eligibility) => emit(
        LoanActionSuccess(
          message: eligibility.isEligible
              ? 'Eligibility passed!'
              : 'Application is currently ineligible.',
          data: {'eligibility': eligibility},
        ),
      ),
    );
  }

  Future<void> _onRequestLoanGuarantor(
    RequestLoanGuarantorRequested event,
    Emitter<LoanState> emit,
  ) async {
    emit(const LoanActionInProgress(message: 'Sending guarantor request...'));
    final result = await requestLoanGuarantor(
      loanApplicationId: event.loanApplicationId,
      guarantorMemberId: event.guarantorMemberId,
    );
    result.fold(
      (failure) => emit(LoanFailure(message: failure.message)),
      (_) => emit(const LoanActionSuccess(message: 'Guarantor request sent successfully!')),
    );
  }

  Future<void> _onLoadGuarantorRequests(
    LoadGuarantorRequestsRequested event,
    Emitter<LoanState> emit,
  ) async {
    emit(LoanLoading());
    final result = await getMyGuarantorRequests();
    result.fold(
      (failure) => emit(LoanFailure(message: failure.message)),
      (requests) => emit(GuarantorRequestsLoaded(requests)),
    );
  }

  Future<void> _onRespondToGuarantorRequest(
    RespondToGuarantorRequestEvent event,
    Emitter<LoanState> emit,
  ) async {
    emit(const LoanActionInProgress(message: 'Submitting guarantee decision...'));
    final result = await respondToGuarantorRequest(
      guarantorRequestId: event.guarantorRequestId,
      accept: event.accept,
    );
    result.fold(
      (failure) => emit(LoanFailure(message: failure.message)),
      (_) => emit(
        LoanActionSuccess(
          message: event.accept
              ? 'Guarantee accepted successfully.'
              : 'Guarantee request rejected.',
        ),
      ),
    );
  }

  Future<void> _onLoadLoanDetails(
    LoadLoanDetailsRequested event,
    Emitter<LoanState> emit,
  ) async {
    emit(LoanLoading());

    final loansResult = await getMyLoans();
    final installmentsResult = await getLoanInstallments(event.loanId);

    if (loansResult.isLeft()) {
      emit(LoanFailure(message: loansResult.fold((l) => l.message, (_) => '')));
      return;
    }
    if (installmentsResult.isLeft()) {
      emit(LoanFailure(message: installmentsResult.fold((l) => l.message, (_) => '')));
      return;
    }

    final loans = loansResult.getOrElse(() => []);
    final loan = loans.firstWhere(
      (l) => l.id == event.loanId,
      orElse: () => throw Exception('Loan not found'),
    );
    final installments = installmentsResult.getOrElse(() => []);

    emit(LoanDetailsLoaded(loan: loan, installments: installments));
  }

  Future<void> _onRequestLoanExtension(
    RequestLoanExtensionRequested event,
    Emitter<LoanState> emit,
  ) async {
    emit(const LoanActionInProgress(message: 'Submitting extension request...'));
    final result = await requestLoanExtension(
      loanId: event.loanId,
      reason: event.reason,
      requestedNewDueDate: event.requestedNewDueDate,
    );
    result.fold(
      (failure) => emit(LoanFailure(message: failure.message)),
      (_) => emit(const LoanActionSuccess(message: 'Extension request submitted for review.')),
    );
  }

  Future<void> _onSubmitLoanRepayment(
    SubmitLoanRepaymentRequested event,
    Emitter<LoanState> emit,
  ) async {
    emit(const LoanActionInProgress(message: 'Uploading payment proof...'));

    String? uploadedStoragePath;
    if (event.filePath != null &&
        event.fileName != null &&
        event.mimeType != null &&
        event.fileSizeBytes != null) {
      final uploadResult = await uploadLoanPaymentProof(
        filePath: event.filePath!,
        fileName: event.fileName!,
        mimeType: event.mimeType!,
        fileSizeBytes: event.fileSizeBytes!,
      );

      final storagePath = uploadResult.fold(
        (failure) {
          emit(LoanFailure(message: failure.message));
          return null;
        },
        (path) => path,
      );

      if (storagePath == null) return;
      uploadedStoragePath = storagePath;
    }

    emit(const LoanActionInProgress(message: 'Recording loan repayment payment...'));

    final result = await submitLoanRepaymentPayment(
      loanId: event.loanId,
      amount: event.amount,
      paymentMethodCode: event.paymentMethodCode,
      externalReference: event.externalReference,
      paymentProofPath: uploadedStoragePath,
      allocations: event.allocations,
    );

    result.fold(
      (failure) => emit(LoanFailure(message: failure.message)),
      (_) => emit(
        const LoanActionSuccess(
          message: 'Loan repayment submitted for verification! It will post once verified.',
        ),
      ),
    );
  }
}
