import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/features/loans/domain/entities/loan_installment_entity.dart';
import 'package:ufg/features/loans/presentation/widgets/installment_tile.dart';

class RepaymentScheduleCard extends StatelessWidget {
  final List<LoanInstallmentEntity> installments;
  final void Function(LoanInstallmentEntity installment)? onPayInstallment;

  const RepaymentScheduleCard({
    super.key,
    required this.installments,
    this.onPayInstallment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (installments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.spacingL),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(AppIcons.calendar.outline, size: 40, color: theme.hintColor),
            const SizedBox(height: AppSizes.spacingS),
            Text(
              'No repayment schedule generated yet.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.calendar.outline, size: AppSizes.iconS, color: colorScheme.primary),
            const SizedBox(width: AppSizes.spacingXs),
            Text(
              'Repayment Schedule (${installments.length} Months)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingM),
        ...installments.map(
          (inst) => InstallmentTile(
            installment: inst,
            onPayTap: onPayInstallment != null ? () => onPayInstallment!(inst) : null,
          ),
        ),
      ],
    );
  }
}
