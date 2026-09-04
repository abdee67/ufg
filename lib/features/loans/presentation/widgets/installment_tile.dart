import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/features/loans/domain/entities/loan_installment_entity.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_status_chip.dart';

class InstallmentTile extends StatelessWidget {
  final LoanInstallmentEntity installment;
  final VoidCallback? onPayTap;

  const InstallmentTile({
    super.key,
    required this.installment,
    this.onPayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormatter = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final isDark = theme.brightness == Brightness.dark;

    final isPaid = installment.isPaid;
    final isOverdue = installment.isOverdue || installment.isDefaulted;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isOverdue
              ? ColorConstants.error.withValues(alpha: 0.35)
              : (isPaid ? ColorConstants.success.withValues(alpha: 0.25) : theme.dividerColor),
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
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isPaid
                          ? ColorConstants.success.withValues(alpha: 0.15)
                          : (isOverdue
                              ? ColorConstants.error.withValues(alpha: 0.15)
                              : colorScheme.primary.withValues(alpha: 0.1)),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${installment.installmentNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPaid
                            ? ColorConstants.success
                            : (isOverdue ? ColorConstants.error : colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingS),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Installment #${installment.installmentNumber}',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Due: ${DateFormat('dd MMM yyyy').format(installment.dueDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOverdue ? ColorConstants.error : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              LoanStatusChip.fromInstallmentStatus(installment.status, installment.hasLatePenalty),
            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount Due:',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                currencyFormatter.format(installment.totalDue),
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (installment.paidAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Paid:', style: theme.textTheme.bodySmall),
                Text(
                  currencyFormatter.format(installment.paidAmount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ColorConstants.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (installment.latePenaltyAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Late Penalty (5%):',
                  style: theme.textTheme.bodySmall?.copyWith(color: ColorConstants.error),
                ),
                Text(
                  currencyFormatter.format(installment.latePenaltyAmount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ColorConstants.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          if (!isPaid && onPayTap != null) ...[
            const SizedBox(height: AppSizes.spacingM),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPayTap,
                icon: Icon(AppIcons.card.outline, size: AppSizes.iconXs),
                label: Text('Pay ${currencyFormatter.format(installment.totalRemainingDue)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
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
