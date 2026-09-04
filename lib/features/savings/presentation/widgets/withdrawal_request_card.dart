import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/utils/formatters.dart';
import 'package:ufg/features/savings/domain/entities/withdrawal_request_entity.dart';
import 'package:ufg/features/savings/presentation/widgets/savings_status_chip.dart';

class WithdrawalRequestCard extends StatelessWidget {
  final WithdrawalRequestEntity request;
  final VoidCallback? onCancelTap;

  const WithdrawalRequestCard({
    super.key,
    required this.request,
    this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

    final bool canCancel = request.isPending || request.isDelayed;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingS + 2),
      padding: const EdgeInsets.all(AppSizes.spacingM + 2),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.money(request.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SavingsStatusChip.fromWithdrawalStatus(
                request.status,
                colorScheme,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingXs),
          Text(
            'Requested: ${dateFormatter.format(request.requestedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (request.reason != null && request.reason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Text(
                'Note: ${request.reason!}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (canCancel && onCancelTap != null) ...[
            const SizedBox(height: AppSizes.spacingS),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onCancelTap,
                icon: Icon(AppIcons.close.outline, size: AppSizes.iconXs),
                label: const Text('Cancel Request'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingXs,
                    vertical: AppSizes.spacingXxs,
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