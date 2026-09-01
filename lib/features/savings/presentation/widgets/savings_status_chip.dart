import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';
import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';

class SavingsStatusChip extends StatelessWidget {
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;
  final IconData? icon;

  const SavingsStatusChip({
    super.key,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
    this.icon,
  });

  factory SavingsStatusChip.fromObligationStatus(
    SavingsObligationStatus status,
    ColorScheme colorScheme,
  ) {
    switch (status) {
      case SavingsObligationStatus.paid:
        return SavingsStatusChip(
          label: 'PAID',
          foregroundColor: Colors.green.shade800,
          backgroundColor: Colors.green.shade50,
          icon: Icons.check_circle_rounded,
        );
      case SavingsObligationStatus.partiallyPaid:
        return SavingsStatusChip(
          label: 'PARTIALLY PAID',
          foregroundColor: Colors.orange.shade800,
          backgroundColor: Colors.orange.shade50,
          icon: Icons.timelapse_rounded,
        );
      case SavingsObligationStatus.late:
        return SavingsStatusChip(
          label: 'LATE (10% PENALTY)',
          foregroundColor: Colors.red.shade800,
          backgroundColor: Colors.red.shade50,
          icon: Icons.warning_amber_rounded,
        );
      case SavingsObligationStatus.waived:
        return SavingsStatusChip(
          label: 'WAIVED',
          foregroundColor: Colors.grey.shade700,
          backgroundColor: Colors.grey.shade100,
          icon: Icons.remove_circle_outline_rounded,
        );
      case SavingsObligationStatus.pending:
        return SavingsStatusChip(
          label: 'PENDING',
          foregroundColor: ColorConstants.navyBlue,
          backgroundColor: ColorConstants.navyBlue.withValues(alpha: 0.1),
          icon: Icons.schedule_rounded,
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
          foregroundColor: Colors.blue.shade800,
          backgroundColor: Colors.blue.shade50,
          icon: Icons.thumb_up_alt_rounded,
        );
      case WithdrawalStatus.delayed:
        return SavingsStatusChip(
          label: 'DELAYED (LIQUIDITY)',
          foregroundColor: Colors.amber.shade900,
          backgroundColor: Colors.amber.shade50,
          icon: Icons.hourglass_top_rounded,
        );
      case WithdrawalStatus.rejected:
        return SavingsStatusChip(
          label: 'REJECTED',
          foregroundColor: Colors.red.shade800,
          backgroundColor: Colors.red.shade50,
          icon: Icons.cancel_rounded,
        );
      case WithdrawalStatus.paid:
        return SavingsStatusChip(
          label: 'PAID OUT',
          foregroundColor: Colors.green.shade800,
          backgroundColor: Colors.green.shade50,
          icon: Icons.check_circle_rounded,
        );
      case WithdrawalStatus.cancelled:
        return SavingsStatusChip(
          label: 'CANCELLED',
          foregroundColor: Colors.grey.shade700,
          backgroundColor: Colors.grey.shade100,
          icon: Icons.block_rounded,
        );
      case WithdrawalStatus.pending:
        return SavingsStatusChip(
          label: 'UNDER REVIEW',
          foregroundColor: ColorConstants.navyBlue,
          backgroundColor: ColorConstants.navyBlue.withValues(alpha: 0.1),
          icon: Icons.pending_actions_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
