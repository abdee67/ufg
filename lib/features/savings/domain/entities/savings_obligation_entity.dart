import 'package:equatable/equatable.dart';

enum SavingsObligationStatus {
  pending,
  partiallyPaid,
  paid,
  late,
  waived,
}

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
    this.createdAt,
    this.updatedAt,
  });

  bool get isPaid => status == SavingsObligationStatus.paid;
  bool get isLate => status == SavingsObligationStatus.late;
  bool get isPending => status == SavingsObligationStatus.pending;
  bool get isPartiallyPaid => status == SavingsObligationStatus.partiallyPaid;

  double get remainingRequired => (requiredAmount - paidAmount).clamp(0.0, double.infinity);
  bool get hasPenalty => latePenaltyAmount > 0;

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
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
        createdAt,
        updatedAt,
      ];
}
