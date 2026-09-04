import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/features/loans/domain/entities/loan_entity.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_status_chip.dart';

class LoanSummaryCard extends StatelessWidget {
  final LoanEntity loan;
  final VoidCallback? onRepayTap;
  final VoidCallback? onDetailsTap;

  const LoanSummaryCard({
    super.key,
    required this.loan,
    this.onRepayTap,
    this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormatter = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    final isDark = theme.brightness == Brightness.dark;
    final gradientColors = isDark
        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
        : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)];

    const onGradient = Colors.white;
    final onGradientSoft = Colors.white.withValues(alpha: 0.8);

    final progress = loan.repaymentProgress;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    AppIcons.wallet.outline,
                    color: onGradient,
                    size: AppSizes.iconS,
                  ),
                  const SizedBox(width: AppSizes.spacingXs),
                  Text(
                    'ACTIVE LOAN',
                    style: TextStyle(
                      color: onGradientSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              LoanStatusChip.fromLoanStatus(loan.status),
            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          Text(
            'Outstanding Balance',
            style: TextStyle(
              color: onGradientSoft,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormatter.format(loan.outstandingBase),
            style: const TextStyle(
              color: onGradient,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paid: ${currencyFormatter.format(loan.totalPaid)}',
                    style: TextStyle(color: onGradientSoft, fontSize: 11),
                  ),
                  Text(
                    'Total: ${currencyFormatter.format(loan.totalRepayment)} (${(progress * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(color: onGradientSoft, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: onGradient.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loan.isOverdue || loan.isDefaulted ? Colors.amberAccent : Colors.greenAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingL),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: onGradient.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              border: Border.all(color: onGradient.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Number',
                      style: TextStyle(color: onGradientSoft, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loan.loanNumber,
                      style: const TextStyle(color: onGradient, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (loan.maturityDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Maturity Date',
                        style: TextStyle(color: onGradientSoft, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy').format(loan.maturityDate!),
                        style: const TextStyle(color: onGradient, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRepayTap,
                  icon: Icon(AppIcons.card.outline, size: AppSizes.iconS - 2),
                  label: const Text('Repay Loan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onGradient,
                    foregroundColor: colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetailsTap,
                  icon: Icon(AppIcons.document.outline, size: AppSizes.iconS - 2),
                  label: const Text('Schedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onGradient,
                    side: BorderSide(color: onGradient.withValues(alpha: 0.7)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
