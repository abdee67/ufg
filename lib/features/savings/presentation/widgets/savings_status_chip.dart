import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/widgets/status_chip.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';
import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';

class SavingsStatusChip extends StatelessWidget {
  const SavingsStatusChip({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  factory SavingsStatusChip.fromObligationStatus(
    SavingsObligationStatus status,
    ColorScheme colorScheme,
  ) {
    switch (status) {
      case SavingsObligationStatus.paid:
        return SavingsStatusChip(
          label: 'PAID',
          tone: StatusTone.success,
          icon: AppIcons.check.outline,
        );
      case SavingsObligationStatus.partiallyPaid:
        return SavingsStatusChip(
          label: 'PARTIALLY PAID',
          tone: StatusTone.warning,
          icon: AppIcons.history.outline,
        );
      case SavingsObligationStatus.late:
        return SavingsStatusChip(
          label: 'LATE (10% PENALTY)',
          tone: StatusTone.error,
          icon: AppIcons.warning.outline,
        );
      case SavingsObligationStatus.waived:
        return SavingsStatusChip(
          label: 'WAIVED',
          tone: StatusTone.neutral,
          icon: AppIcons.close.outline,
        );
      case SavingsObligationStatus.pending:
        return SavingsStatusChip(
          label: 'PENDING',
          tone: StatusTone.info,
          icon: AppIcons.calendar.outline,
        );
    }
  }

  factory SavingsStatusChip.fromWithdrawalStatus(
    WithdrawalStatus status,
    ColorScheme colorScheme,
  ) {
    switch (status) {
      case WithdrawalStatus.approved:
        return SavingsStatusChip(
          label: 'APPROVED',
          tone: StatusTone.success,
          icon: AppIcons.check.outline,
        );
      case WithdrawalStatus.delayed:
        return SavingsStatusChip(
          label: 'DELAYED (LIQUIDITY)',
          tone: StatusTone.warning,
          icon: AppIcons.clock.outline,
        );
      case WithdrawalStatus.rejected:
        return SavingsStatusChip(
          label: 'REJECTED',
          tone: StatusTone.error,
          icon: AppIcons.close.outline,
        );
      case WithdrawalStatus.paid:
        return SavingsStatusChip(
          label: 'PAID OUT',
          tone: StatusTone.success,
          icon: AppIcons.check.outline,
        );
      case WithdrawalStatus.cancelled:
        return SavingsStatusChip(
          label: 'CANCELLED',
          tone: StatusTone.neutral,
          icon: AppIcons.close.outline,
        );
      case WithdrawalStatus.pending:
        return SavingsStatusChip(
          label: 'UNDER REVIEW',
          tone: StatusTone.info,
          icon: AppIcons.history.outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusChip(label: label, tone: tone, icon: icon);
  }
}