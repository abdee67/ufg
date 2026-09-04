import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/widgets/status_chip.dart';
import 'package:ufg/features/loans/domain/entities/guarantor_request_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_application_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_installment_entity.dart';

class LoanStatusChip extends StatelessWidget {
  const LoanStatusChip({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  factory LoanStatusChip.fromLoanStatus(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return LoanStatusChip(
          label: 'ACTIVE',
          tone: StatusTone.success,
          icon: AppIcons.check.outline,
        );
      case LoanStatus.paid:
        return LoanStatusChip(
          label: 'PAID',
          tone: StatusTone.success,
          icon: AppIcons.check.outline,
        );
      case LoanStatus.overdue:
        return LoanStatusChip(
          label: 'OVERDUE (5% PENALTY)',
          tone: StatusTone.error,
          icon: AppIcons.warning.outline,
        );
      case LoanStatus.defaulted:
        return LoanStatusChip(
          label: 'SERIOUS DEFAULT (60+ DAYS)',
          tone: StatusTone.error,
          icon: AppIcons.warning.outline,
        );
      case LoanStatus.readyForDisbursement:
        return LoanStatusChip(
          label: 'READY FOR DISBURSEMENT',
          tone: StatusTone.info,
          icon: AppIcons.card.outline,
        );
      case LoanStatus.approved:
        return LoanStatusChip(
          label: 'APPROVED (2/2)',
          tone: StatusTone.info,
          icon: AppIcons.check.outline,
        );
      case LoanStatus.cancelled:
        return LoanStatusChip(
          label: 'CANCELLED',
          tone: StatusTone.neutral,
          icon: AppIcons.close.outline,
        );
      case LoanStatus.recovered:
        return LoanStatusChip(
          label: 'RECOVERED',
          tone: StatusTone.warning,
          icon: AppIcons.shield.outline,
        );
    }
  }

  factory LoanStatusChip.fromApplicationStatus(
    LoanApplicationStatus status, [
    int approvalCount = 0,
  ]) {
    switch (status) {
      case LoanApplicationStatus.approved:
        return LoanStatusChip(
          label: 'APPROVED (2/2)',
          tone: StatusTone.success,
          icon: AppIcons.check.outline,
        );
      case LoanApplicationStatus.underReview:
        return LoanStatusChip(
          label: approvalCount == 1 ? 'REVIEW (1/2 APPROVALS)' : 'UNDER REVIEW',
          tone: StatusTone.info,
          icon: AppIcons.clock.outline,
        );
      case LoanApplicationStatus.submitted:
        return LoanStatusChip(
          label: 'SUBMITTED',
          tone: StatusTone.info,
          icon: AppIcons.send.outline,
        );
      case LoanApplicationStatus.eligible:
        return LoanStatusChip(
          label: 'ELIGIBLE',
          tone: StatusTone.success,
          icon: AppIcons.check.outline,
        );
      case LoanApplicationStatus.ineligible:
        return LoanStatusChip(
          label: 'INELIGIBLE',
          tone: StatusTone.error,
          icon: AppIcons.close.outline,
        );
      case LoanApplicationStatus.rejected:
        return LoanStatusChip(
          label: 'REJECTED',
          tone: StatusTone.error,
          icon: AppIcons.close.outline,
        );
      case LoanApplicationStatus.cancelled:
        return LoanStatusChip(
          label: 'CANCELLED',
          tone: StatusTone.neutral,
          icon: AppIcons.close.outline,
        );
      case LoanApplicationStatus.expired:
        return LoanStatusChip(
          label: 'EXPIRED',
          tone: StatusTone.neutral,
          icon: AppIcons.clock.outline,
        );
      case LoanApplicationStatus.draft:
        return LoanStatusChip(
          label: 'DRAFT',
          tone: StatusTone.neutral,
          icon: AppIcons.document.outline,
        );
    }
  }

  factory LoanStatusChip.fromInstallmentStatus(
    InstallmentStatus status, [
    bool hasPenalty = false,
  ]) {
    switch (status) {
      case InstallmentStatus.paid:
        return LoanStatusChip(
          label: 'PAID',
          tone: StatusTone.success,
          icon: AppIcons.check.outline,
        );
      case InstallmentStatus.partiallyPaid:
        return LoanStatusChip(
          label: 'PARTIAL',
          tone: StatusTone.warning,
          icon: AppIcons.history.outline,
        );
      case InstallmentStatus.overdue:
        return LoanStatusChip(
          label: hasPenalty ? 'OVERDUE (+5% PENALTY)' : 'OVERDUE',
          tone: StatusTone.error,
          icon: AppIcons.warning.outline,
        );
      case InstallmentStatus.defaulted:
        return LoanStatusChip(
          label: 'DEFAULTED',
          tone: StatusTone.error,
          icon: AppIcons.warning.outline,
        );
      case InstallmentStatus.pending:
        return LoanStatusChip(
          label: 'UPCOMING',
          tone: StatusTone.neutral,
          icon: AppIcons.calendar.outline,
        );
    }
  }

  factory LoanStatusChip.fromGuarantorStatus(GuarantorStatus status) {
    switch (status) {
      case GuarantorStatus.accepted:
        return LoanStatusChip(
          label: 'GUARANTEE ACCEPTED',
          tone: StatusTone.success,
          icon: AppIcons.check.outline,
        );
      case GuarantorStatus.rejected:
        return LoanStatusChip(
          label: 'REJECTED BY GUARANTOR',
          tone: StatusTone.error,
          icon: AppIcons.close.outline,
        );
      case GuarantorStatus.released:
        return LoanStatusChip(
          label: 'GUARANTEE RELEASED',
          tone: StatusTone.neutral,
          icon: AppIcons.shield.outline,
        );
      case GuarantorStatus.replaced:
        return LoanStatusChip(
          label: 'GUARANTOR REPLACED',
          tone: StatusTone.info,
          icon: AppIcons.user.outline,
        );
      case GuarantorStatus.requested:
        return LoanStatusChip(
          label: 'AWAITING GUARANTOR',
          tone: StatusTone.warning,
          icon: AppIcons.clock.outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: label,
      tone: tone,
      icon: icon,
    );
  }
}
