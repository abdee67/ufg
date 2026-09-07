import 'package:equatable/equatable.dart';
import 'package:ufg/features/loans/domain/entities/guarantor_request_entity.dart';
import 'package:ufg/features/loans/domain/entities/guarantor_candidate_entity.dart';
import 'package:ufg/features/loans/domain/entities/member_loan_limit_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_application_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_eligibility_result_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_installment_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';

abstract class LoanState extends Equatable {
  const LoanState();

  @override
  List<Object?> get props => [];
}

class LoanInitial extends LoanState {}

class LoanLoading extends LoanState {}

class LoansDashboardLoaded extends LoanState {
  final List<LoanEntity> activeLoans;
  final List<LoanApplicationEntity> applications;
  final List<LoanProductEntity> products;
  final List<GuarantorRequestEntity> pendingGuarantorRequests;

  const LoansDashboardLoaded({
    required this.activeLoans,
    required this.applications,
    required this.products,
    this.pendingGuarantorRequests = const [],
  });

  LoanEntity? get primaryActiveLoan =>
      activeLoans.isNotEmpty ? activeLoans.first : null;

  @override
  List<Object?> get props => [
    activeLoans,
    applications,
    products,
    pendingGuarantorRequests,
  ];
}

class LoanProductsLoaded extends LoanState {
  final List<LoanProductEntity> products;

  const LoanProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class MemberLoanLimitLoaded extends LoanState {
  final MemberLoanLimitEntity limit;
  const MemberLoanLimitLoaded(this.limit);

  @override
  List<Object?> get props => [limit];
}

class LoanGuarantorSearchLoaded extends LoanState {
  final List<GuarantorCandidateEntity> candidates;
  const LoanGuarantorSearchLoaded(this.candidates);

  @override
  List<Object?> get props => [candidates];
}

class OutsiderLoanProductLoaded extends LoanState {
  final LoanProductEntity product;
  const OutsiderLoanProductLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class LoanApplicationDetailLoaded extends LoanState {
  final LoanApplicationEntity application;
  final LoanEligibilityResultEntity? eligibility;
  final GuarantorRequestEntity? guarantor;

  const LoanApplicationDetailLoaded({
    required this.application,
    this.eligibility,
    this.guarantor,
  });

  @override
  List<Object?> get props => [application, eligibility, guarantor];
}

class LoanDetailsLoaded extends LoanState {
  final LoanEntity loan;
  final List<LoanInstallmentEntity> installments;

  const LoanDetailsLoaded({required this.loan, required this.installments});

  @override
  List<Object?> get props => [loan, installments];
}

class GuarantorRequestsLoaded extends LoanState {
  final List<GuarantorRequestEntity> requests;

  const GuarantorRequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

class LoanActionInProgress extends LoanState {
  final String? message;

  const LoanActionInProgress({this.message});

  @override
  List<Object?> get props => [message];
}

class LoanActionSuccess extends LoanState {
  final String message;
  final Map<String, dynamic>? data;

  const LoanActionSuccess({required this.message, this.data});

  @override
  List<Object?> get props => [message, data];
}

class LoanFailure extends LoanState {
  final String message;

  const LoanFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
