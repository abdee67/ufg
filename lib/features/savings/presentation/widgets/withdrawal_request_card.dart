import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final currencyFormatter = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

    final bool canCancel = request.isPending || request.isDelayed;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormatter.format(request.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SavingsStatusChip.fromWithdrawalStatus(request.status, colorScheme),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Requested: ${dateFormatter.format(request.requestedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          if (request.reason != null && request.reason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Note: ${request.reason!}',
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          if (canCancel && onCancelTap != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onCancelTap,
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel Request'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
