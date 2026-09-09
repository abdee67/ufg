import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ufg/core/errors/failures.dart';
import 'package:ufg/features/auth/domain/usecases/get_current_profile.dart';
import 'package:ufg/features/savings/domain/entities/savings_history_item_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_summary_entity.dart';
import 'package:ufg/features/savings/domain/usecases/get_savings_summary.dart';
import 'package:ufg/features/savings/domain/usecases/get_savings_history.dart';
import 'package:ufg/features/loans/domain/usecases/get_my_loans.dart';
import 'package:ufg/features/loans/domain/entities/loan_entity.dart';
import '../../domain/usecases/search_content.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetCurrentProfile getCurrentProfile;
  final GetSavingsSummary getSavingsSummary;
  final GetSavingsHistory getSavingsHistory;
  final GetMyLoans getMyLoans;
  final SearchContent searchContent;

  HomeBloc({
    required this.getCurrentProfile,
    required this.getSavingsSummary,
    required this.getSavingsHistory,
    required this.getMyLoans,
    required this.searchContent,
  }) : super(HomeInitial()) {
    on<FetchHomeData>(_onFetchHomeData);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<ClearSearch>((event, emit) => emit(HomeInitial()));
  }

  Future<void> _onFetchHomeData(
    FetchHomeData event,
    Emitter<HomeState> emit,
  ) async {
    if (!event.refresh) {
      emit(HomeLoading());
    }

    final profileResult = await getCurrentProfile();

    await profileResult.fold(
      (failure) async => emit(HomeLoadFailure(failure.message)),
      (profile) async {
        // Fetch other data in parallel
        final results = await Future.wait([
          getSavingsSummary(),
          getSavingsHistory(),
          getMyLoans(),
        ]);

        final savingsSummaryResult = results[0] as Either<Failures, SavingsSummaryEntity>;
        final savingsHistoryResult = results[1] as Either<Failures, List<SavingsHistoryItemEntity>>;
        final loansResult = results[2] as Either<Failures, List<LoanEntity>>;

        final savingsSummary = savingsSummaryResult.fold((_) => null, (s) => s);
        final recentActivity = savingsHistoryResult.fold((_) => <SavingsHistoryItemEntity>[], (h) => h.take(5).toList());
        final activeLoans = loansResult.fold((_) => <LoanEntity>[], (l) => l.where((loan) => loan.status == LoanStatus.active).toList());

        emit(HomeLoadSuccess(
          profile: profile,
          savingsSummary: savingsSummary,
          recentActivity: recentActivity,
          activeLoans: activeLoans,
        ));
      },

    );
  }

  Future<void> _onSearchQueryChanged(
      SearchQueryChanged event,
      Emitter<HomeState> emit,
      ) async {
    if (event.query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    final result = await searchContent(event.query);

    result.fold(
          (failure) => emit(SearchFailure(failure.message)),
          (results) => emit(SearchSuccess(results)),
    );
  }
}
