import 'package:equatable/equatable.dart';

enum SavingsObligationStatus { pending, partiallyPaid, paid, late, waived }

class SavingsObligationEntity extends Equatable {
  final String id;
  final int periodYear;
  final int periodMonth;
  final double requiredAmount;
  final DateTime dueDate;
  final double paidAmount;
  final double latePenaltyAmount;
  final SavingsObligationStatus status;
  final double totalDue;
  final bool hasPendingPayment;
  final double pendingPaymentAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SavingsObligationEntity({
    required this.id,
    required this.periodYear,
    required this.periodMonth,
    required this.requiredAmount,
    required this.dueDate,
    required this.paidAmount,
    required this.latePenaltyAmount,
    required this.status,
    required this.totalDue,
    this.hasPendingPayment = false,
    this.pendingPaymentAmount = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPaid => status == SavingsObligationStatus.paid;
  bool get isLate =>
      status == SavingsObligationStatus.late ||
      (!isPaid && DateTime.now().isAfter(dueDate));
  bool get isPending => status == SavingsObligationStatus.pending && !isLate;
  bool get isPartiallyPaid =>
      status == SavingsObligationStatus.partiallyPaid && !isLate;

  SavingsObligationStatus get effectiveStatus {
    if (isPaid) return SavingsObligationStatus.paid;
    if (isLate) return SavingsObligationStatus.late;
    return status;
  }

  double get remainingRequired =>
      (requiredAmount - paidAmount).clamp(0.0, double.infinity);
  bool get hasPenalty => isLate || latePenaltyAmount > 0;
  double get effectivePenaltyAmount => latePenaltyAmount > 0
      ? latePenaltyAmount
      : (isLate ? (requiredAmount * 0.10).roundToDouble() : 0.0);
  double get effectiveTotalDue =>
      totalDue > (remainingRequired + effectivePenaltyAmount)
      ? totalDue
      : (remainingRequired + effectivePenaltyAmount);

  String get monthName {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (periodMonth >= 1 && periodMonth <= 12) {
      return months[periodMonth - 1];
    }
    return 'Month $periodMonth';
  }

  String get periodLabel => '$monthName $periodYear';

  @override
  List<Object?> get props => [
    id,
    periodYear,
    periodMonth,
    requiredAmount,
    dueDate,
    paidAmount,
    latePenaltyAmount,
    status,
    totalDue,
    hasPendingPayment,
    pendingPaymentAmount,
    createdAt,
    updatedAt,
  ];
}
