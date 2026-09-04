import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';

class LoanFinancialBreakdown extends StatelessWidget {
  final double principal;
  final double serviceChargeRate;
  final int termMonths;

  const LoanFinancialBreakdown({
    super.key,
    required this.principal,
    required this.serviceChargeRate,
    this.termMonths = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    final serviceCharge = principal * serviceChargeRate;
    final totalRepayment = principal + serviceCharge;
    final monthlyInstallment = termMonths > 0 ? totalRepayment / termMonths : 0.0;
    final serviceRatePercentage = (serviceChargeRate * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.calculator.outline, size: AppSizes.iconS, color: colorScheme.primary),
              const SizedBox(width: AppSizes.spacingXs),
              Text(
                'Financial Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          _row('Requested Principal', currencyFormatter.format(principal), theme),
          const SizedBox(height: AppSizes.spacingS),
          _row(
            'One-Time Service Charge ($serviceRatePercentage%)',
            currencyFormatter.format(serviceCharge),
            theme,
            isHighlight: true,
          ),
          const SizedBox(height: AppSizes.spacingS),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.spacingS),
          _row(
            'Total Repayment Obligation',
            currencyFormatter.format(totalRepayment),
            theme,
            isBold: true,
          ),
          const SizedBox(height: AppSizes.spacingS),
          _row(
            'Monthly Installment ($termMonths months)',
            '${currencyFormatter.format(monthlyInstallment)} / month',
            theme,
            valueColor: colorScheme.primary,
            isBold: true,
          ),
          const SizedBox(height: AppSizes.spacingM),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.info.outline, size: 14, color: colorScheme.primary),
                const SizedBox(width: AppSizes.spacingXs),
                Expanded(
                  child: Text(
                    'The $serviceRatePercentage% service charge is a one-time flat fee calculated from the original principal. No compound interest or early-repayment penalties.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
    bool isHighlight = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isHighlight
                ? theme.colorScheme.primary
                : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? (isBold ? theme.colorScheme.primary : null),
          ),
        ),
      ],
    );
  }
}
