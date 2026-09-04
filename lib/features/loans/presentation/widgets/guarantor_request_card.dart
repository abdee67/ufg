import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/features/loans/domain/entities/guarantor_request_entity.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_status_chip.dart';

class GuarantorRequestCard extends StatelessWidget {
  final GuarantorRequestEntity request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const GuarantorRequestCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormatter = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final isDark = theme.brightness == Brightness.dark;

    final isPending = request.isPending;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingM),
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isPending
              ? ColorConstants.warning.withValues(alpha: 0.4)
              : theme.dividerColor,
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
                  Icon(AppIcons.user.outline, size: AppSizes.iconS, color: colorScheme.primary),
                  const SizedBox(width: AppSizes.spacingXs),
                  Text(
                    'Borrower Guarantee',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              LoanStatusChip.fromGuarantorStatus(request.status),
            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          _detailRow('Borrower:', request.borrowerName ?? 'Outsider Applicant', theme, isBold: true),
          if (request.borrowerPhone != null && request.borrowerPhone!.isNotEmpty)
            _detailRow('Phone:', request.borrowerPhone!, theme),
          _detailRow('Requested Loan:', currencyFormatter.format(request.requestedLoanAmount), theme),
          _detailRow('One-Time Fee (15%):', currencyFormatter.format(request.serviceChargeAmount), theme),
          _detailRow('Total Repayment:', currencyFormatter.format(request.totalRepayment), theme, isHighlight: true),
          _detailRow('Repayment Period:', '${request.termMonths} Months', theme),
          const SizedBox(height: AppSizes.spacingS),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.spacingS),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorConstants.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              border: Border.all(color: ColorConstants.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.warning.outline, size: 16, color: ColorConstants.warning),
                const SizedBox(width: AppSizes.spacingXs),
                Expanded(
                  child: Text(
                    'As a guarantor, you agree that if the borrower defaults after 60 days, recovery may be initiated from your eligible savings/security. You may only guarantee 1 active outsider loan at a time.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: isDark ? ColorConstants.textSecondaryDark : const Color(0xFF9A6B00),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isPending && onAccept != null && onReject != null) ...[
            const SizedBox(height: AppSizes.spacingL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConstants.error,
                      side: BorderSide(color: ColorConstants.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppSizes.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Accept Guarantee'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, ThemeData theme, {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold || isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
