import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ufg/features/savings/domain/usecases/cancel_withdrawal_request.dart';
import 'package:ufg/features/savings/domain/usecases/get_savings_history.dart';
import 'package:ufg/features/savings/domain/usecases/get_savings_obligations.dart';
import 'package:ufg/features/savings/domain/usecases/get_savings_summary.dart';
import 'package:ufg/features/savings/domain/usecases/get_withdrawal_requests.dart';
import 'package:ufg/features/savings/domain/usecases/request_savings_withdrawal.dart';
import 'package:ufg/features/savings/domain/usecases/submit_savings_payment.dart';
import 'package:ufg/features/savings/domain/usecases/upload_payment_proof.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_event.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_state.dart';

class SavingsBloc extends Bloc<SavingsEvent, SavingsState> {
  final GetSavingsSummary getSavingsSummary;
  final GetSavingsObligations getSavingsObligations;
  final GetSavingsHistory getSavingsHistory;
  final SubmitSavingsPayment submitSavingsPayment;
  final RequestSavingsWithdrawal requestSavingsWithdrawal;
  final CancelWithdrawalRequest cancelWithdrawalRequest;
  final GetWithdrawalRequests getWithdrawalRequests;
  final UploadPaymentProof uploadPaymentProof;

  SavingsBloc({
    required this.getSavingsSummary,
    required this.getSavingsObligations,
    required this.getSavingsHistory,
    required this.submitSavingsPayment,
    required this.requestSavingsWithdrawal,
    required this.cancelWithdrawalRequest,
    required this.getWithdrawalRequests,
    required this.uploadPaymentProof,
  }) : super(SavingsInitial()) {
    on<LoadSavingsSummaryRequested>(_onLoadSavingsSummary);
    on<LoadSavingsObligationsRequested>(_onLoadSavingsObligations);
    on<LoadSavingsHistoryRequested>(_onLoadSavingsHistory);
    on<LoadWithdrawalRequestsRequested>(_onLoadWithdrawalRequests);
    on<SubmitSavingsPaymentRequested>(_onSubmitSavingsPayment);
    on<RequestSavingsWithdrawalRequested>(_onRequestSavingsWithdrawal);
    on<CancelWithdrawalRequested>(_onCancelWithdrawal);
  }

  Future<void> _onLoadSavingsSummary(
    LoadSavingsSummaryRequested event,
    Emitter<SavingsState> emit,
  ) async {
    emit(SavingsLoading());
    final result = await getSavingsSummary();
    result.fold(
      (failure) => emit(SavingsFailure(message: failure.message)),
      (summary) => emit(SavingsSummaryLoaded(summary: summary)),
    );
  }

  Future<void> _onLoadSavingsObligations(
    LoadSavingsObligationsRequested event,
    Emitter<SavingsState> emit,
  ) async {
    emit(SavingsLoading());
    final result = await getSavingsObligations();
    result.fold(
      (failure) => emit(SavingsFailure(message: failure.message)),
      (obligations) => emit(SavingsObligationsLoaded(obligations: obligations)),
    );
  }

  Future<void> _onLoadSavingsHistory(
    LoadSavingsHistoryRequested event,
    Emitter<SavingsState> emit,
  ) async {
    emit(SavingsLoading());
    final result = await getSavingsHistory();
    result.fold(
      (failure) => emit(SavingsFailure(message: failure.message)),
      (history) => emit(SavingsHistoryLoaded(history: history)),
    );
  }

  Future<void> _onLoadWithdrawalRequests(
    LoadWithdrawalRequestsRequested event,
    Emitter<SavingsState> emit,
  ) async {
    emit(SavingsLoading());
    final result = await getWithdrawalRequests();
    result.fold(
      (failure) => emit(SavingsFailure(message: failure.message)),
      (requests) => emit(WithdrawalRequestsLoaded(requests: requests)),
    );
  }

  Future<void> _onSubmitSavingsPayment(
    SubmitSavingsPaymentRequested event,
    Emitter<SavingsState> emit,
  ) async {
    emit(const SavingsActionInProgress(actionMessage: 'Submitting payment proof...'));

    String? storagePath;
    if (event.filePath != null && event.fileName != null && event.mimeType != null && event.fileSizeBytes != null) {
      final uploadRes = await uploadPaymentProof(
        filePath: event.filePath!,
        fileName: event.fileName!,
        mimeType: event.mimeType!,
        fileSizeBytes: event.fileSizeBytes!,
      );

      final uploadFailed = uploadRes.fold(
        (failure) {
          emit(SavingsFailure(message: failure.message));
          return true;
        },
        (path) {
          storagePath = path;
          return false;
        },
      );

      if (uploadFailed) return;
    }

    emit(const SavingsActionInProgress(actionMessage: 'Recording payment...'));

    final result = await submitSavingsPayment(
      amount: event.amount,
      paymentMethodCode: event.paymentMethodCode,
      externalReference: event.externalReference,
      paymentProofPath: storagePath,
      obligationId: event.obligationId,
    );

    result.fold(
      (failure) => emit(SavingsFailure(message: failure.message)),
      (data) {
        emit(SavingsActionSuccess(
          message: 'Savings payment submitted for admin verification!',
          data: data,
        ));
      },
    );
  }

  Future<void> _onRequestSavingsWithdrawal(
    RequestSavingsWithdrawalRequested event,
    Emitter<SavingsState> emit,
  ) async {
    emit(const SavingsActionInProgress(actionMessage: 'Submitting withdrawal request...'));

    final result = await requestSavingsWithdrawal(
      amount: event.amount,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(SavingsFailure(message: failure.message)),
      (data) {
        emit(SavingsActionSuccess(
          message: 'Withdrawal request submitted successfully!',
          data: data,
        ));
      },
    );
  }

  Future<void> _onCancelWithdrawal(
    CancelWithdrawalRequested event,
    Emitter<SavingsState> emit,
  ) async {
    emit(const SavingsActionInProgress(actionMessage: 'Cancelling withdrawal request...'));

    final result = await cancelWithdrawalRequest(
      withdrawalRequestId: event.withdrawalRequestId,
    );

    result.fold(
      (failure) => emit(SavingsFailure(message: failure.message)),
      (data) {
        emit(const SavingsActionSuccess(
          message: 'Withdrawal request cancelled.',
        ));
      },
    );
  }
}
