import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';

class LoanProductCard extends StatelessWidget {
  final LoanProductEntity product;
  final bool isSelected;
  final VoidCallback onTap;

  const LoanProductCard({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormatter = NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 0,
    );

    final servicePercentage = (product.serviceChargeRate * 100).toStringAsFixed(
      0,
    );
    final isMember = product.isMemberLoan;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.spacingL),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.06)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isMember
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : theme.colorScheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isMember
                            ? AppIcons.user.outline
                            : AppIcons.shield.outline,
                        size: AppSizes.iconXs,
                        color: isMember
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(width: AppSizes.spacingXxs),
                      Text(
                        isMember ? 'MEMBER LOAN' : 'OUTSIDER LOAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMember
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? colorScheme.primary : theme.hintColor,
                  size: AppSizes.iconM,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingM),
            Text(
              product.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXs),
            Text(
              isMember
                  ? '$servicePercentage% one-time service charge • Up to ${currencyFormatter.format(product.maxAmount)} • ${product.termMonths} months repayment'
                  : '$servicePercentage% one-time service charge • Requires active member guarantor • ${product.termMonths} months repayment',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
