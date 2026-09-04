import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/features/loans/domain/entities/loan_eligibility_result_entity.dart';

class EligibilityChecklistWidget extends StatelessWidget {
  final LoanEligibilityResultEntity eligibility;

  const EligibilityChecklistWidget({
    super.key,
    required this.eligibility,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final containerColor = isDark
        ? ColorConstants.surfaceDark
        : colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: eligibility.isEligible
              ? ColorConstants.success.withValues(alpha: 0.3)
              : ColorConstants.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                eligibility.isEligible
                    ? AppIcons.check.outline
                    : AppIcons.warning.outline,
                color: eligibility.isEligible
                    ? ColorConstants.success
                    : ColorConstants.error,
                size: AppSizes.iconM,
              ),
              const SizedBox(width: AppSizes.spacingS),
              Text(
                eligibility.isEligible
                    ? 'Eligibility Verified'
                    : 'Eligibility Requirements',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: eligibility.isEligible
                      ? ColorConstants.success
                      : ColorConstants.error,
                ),
              ),
            ],
          ),
          if (eligibility.message != null && eligibility.message!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.spacingS),
            Text(
              eligibility.message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.spacingM),
          const Divider(height: 1),
          const SizedBox(height: AppSizes.spacingM),
          if (eligibility.checks.isNotEmpty)
            ...eligibility.checks.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: item.passed
                            ? ColorConstants.success.withValues(alpha: 0.15)
                            : ColorConstants.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.passed
                            ? AppIcons.check.outline
                            : AppIcons.close.outline,
                        size: 14,
                        color: item.passed
                            ? ColorConstants.success
                            : ColorConstants.error,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.details.isNotEmpty)
                            Text(
                              item.details,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
