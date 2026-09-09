import 'package:equatable/equatable.dart';
import 'package:ufg/features/auth/domain/entities/profile_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_summary_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_history_item_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_entity.dart';

import '../../domain/entities/search_result.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoadSuccess extends HomeState {
  final ProfileEntity profile;
  final SavingsSummaryEntity? savingsSummary;
  final List<SavingsHistoryItemEntity> recentActivity;
  final List<LoanEntity> activeLoans;

  const HomeLoadSuccess({
    required this.profile,
    this.savingsSummary,
    this.recentActivity = const [],
    this.activeLoans = const [],
  });

  @override
  List<Object?> get props => [profile, savingsSummary, recentActivity, activeLoans];
}

class HomeLoadFailure extends HomeState {
  final String message;

  const HomeLoadFailure(this.message);

  @override
  List<Object?> get props => [message];
}
class SearchInitial extends HomeState {}

class SearchLoading extends HomeState {}

class SearchSuccess extends HomeState {
  final List<SearchResult> results;

  const SearchSuccess(this.results);

  @override
  List<Object?> get props => [results];
}

class SearchFailure extends HomeState {
  final String message;

  const SearchFailure(this.message);

  @override
  List<Object?> get props => [message];
}
