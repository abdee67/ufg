import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/utils/formatters.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';
import 'package:ufg/features/savings/presentation/widgets/savings_status_chip.dart';

class MonthlyObligationCard extends StatelessWidget {
  final SavingsObligationEntity obligation;
  final VoidCallback onPayTap;

  const MonthlyObligationCard({
    super.key,
    required this.obligation,
    required this.onPayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dateFormatter = DateFormat('dd MMM yyyy');

    final bool isLate = obligation.isLate;
    final bool isPaid = obligation.isPaid;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.6);
    final lateBg = isDark
        ? ColorConstants.errorSubtleDark
        : ColorConstants.errorSubtle;
    final lateFg = isDark
        ? colorScheme.error.withValues(alpha: 0.9)
        : colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM + 2),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isLate ? lateFg.withValues(alpha: 0.4) : theme.dividerColor,
          width: isLate ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.spacingXs),
                    decoration: BoxDecoration(
                      color: isLate
                          ? lateBg
                          : colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      AppIcons.calendar.outline,
                      color: isLate ? lateFg : colorScheme.primary,
                      size: AppSizes.iconS - 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    obligation.periodLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SavingsStatusChip.fromObligationStatus(
                obligation.status,
                colorScheme,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required Saving',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.money(obligation.requiredAmount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paid Amount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.money(obligation.paidAmount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: obligation.paidAmount > 0
                          ? ColorConstants.success
                          : null,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due Date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormatter.format(obligation.dueDate),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isLate ? lateFg : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (obligation.hasPenalty) ...[
            const SizedBox(height: AppSizes.spacingS + 2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingS,
                vertical: AppSizes.spacingXs,
              ),
              decoration: BoxDecoration(
                color: lateBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
                border: Border.all(color: lateFg.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.info.outline, color: lateFg, size: AppSizes.iconXs),
                  const SizedBox(width: AppSizes.spacingXs),
                  Expanded(
                    child: Text(
                      '10% Late Penalty (${Formatters.money(obligation.latePenaltyAmount)}) recorded separately.',
                      style: TextStyle(
                        color: lateFg,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!isPaid) ...[
            const SizedBox(height: AppSizes.spacingM),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPayTap,
                icon: Icon(
                  AppIcons.payments.outline,
                  size: AppSizes.iconS - 2,
                ),
                label: Text(
                  isLate
                      ? 'Pay Obligation & Penalty (${Formatters.money(obligation.totalDue)})'
                      : 'Pay Contribution (${Formatters.money(obligation.totalDue)})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLate
                      ? colorScheme.error
                      : colorScheme.primary,
                  foregroundColor: ColorConstants.onBrand,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.spacingS,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSizes.radiusChip + 6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}