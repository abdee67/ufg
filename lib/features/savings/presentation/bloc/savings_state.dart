import 'package:equatable/equatable.dart';
import 'package:ufg/features/savings/domain/entities/savings_history_item_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_summary_entity.dart';
import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';

abstract class SavingsState extends Equatable {
  const SavingsState();

  @override
  List<Object?> get props => [];
}

class SavingsInitial extends SavingsState {}

class SavingsLoading extends SavingsState {}

class SavingsSummaryLoaded extends SavingsState {
  final SavingsSummaryEntity summary;

  const SavingsSummaryLoaded({required this.summary});

  @override
  List<Object?> get props => [summary];
}

class SavingsObligationsLoaded extends SavingsState {
  final List<SavingsObligationEntity> obligations;

  const SavingsObligationsLoaded({required this.obligations});

  @override
  List<Object?> get props => [obligations];
}

class SavingsHistoryLoaded extends SavingsState {
  final List<SavingsHistoryItemEntity> history;

  const SavingsHistoryLoaded({required this.history});

  @override
  List<Object?> get props => [history];
}

class WithdrawalRequestsLoaded extends SavingsState {
  final List<WithdrawalRequestEntity> requests;

  const WithdrawalRequestsLoaded({required this.requests});

  @override
  List<Object?> get props => [requests];
}

class SavingsActionInProgress extends SavingsState {
  final String actionMessage;

  const SavingsActionInProgress({required this.actionMessage});

  @override
  List<Object?> get props => [actionMessage];
}

class SavingsActionSuccess extends SavingsState {
  final String message;
  final dynamic data;

  const SavingsActionSuccess({required this.message, this.data});

  @override
  List<Object?> get props => [message, data];
}

class SavingsFailure extends SavingsState {
  final String message;

  const SavingsFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
