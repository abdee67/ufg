import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/utils/formatters.dart';
import 'package:ufg/features/savings/domain/entities/savings_history_item_entity.dart';

class SavingsTransactionTile extends StatelessWidget {
  final SavingsHistoryItemEntity item;

  const SavingsTransactionTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

    final bool isCredit = item.isCredit;
    final accentColor = isCredit
        ? ColorConstants.success
        : (isDark ? ColorConstants.warningDark : ColorConstants.warning);
    final statusLower = item.status.toLowerCase();
    final bool isCompleted = statusLower == 'posted' || statusLower == 'paid';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Icon(
              isCredit ? AppIcons.arrowDown.outline : AppIcons.arrowUp.outline,
              color: accentColor,
              size: AppSizes.iconS,
            ),
          ),
          const SizedBox(width: AppSizes.spacingS + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.reference} • ${dateFormatter.format(item.timestamp)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.signedMoney(isCredit ? item.amount : -item.amount),
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (isCompleted
                          ? ColorConstants.success
                          : theme.colorScheme.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    color: isCompleted
                        ? ColorConstants.success
                        : theme.colorScheme.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
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