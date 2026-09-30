import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/features/notifications/domain/entities/notification_entity.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.65);
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        decoration: BoxDecoration(
          color: isUnread
              ? colorScheme.primary.withValues(alpha: 0.06)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(
            color: isUnread
                ? colorScheme.primary.withValues(alpha: 0.25)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accentColor(colorScheme).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Icon(
                _iconData(),
                size: AppSizes.iconS,
                color: _accentColor(colorScheme),
              ),
            ),
            const SizedBox(width: AppSizes.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(
                            top: 6,
                            left: AppSizes.spacingXs,
                          ),
                          decoration: const BoxDecoration(
                            color: ColorConstants.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingXxs),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryText,
                      height: 1.4,
                    ),
                  ),
                  // @@TILE_CONTINUE@@
                  const SizedBox(height: AppSizes.spacingXs),
                  Row(
                    children: [
                      Text(
                        _relativeTime(notification.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: secondaryText,
                        ),
                      ),
                      if (notification.isCritical) ...[
                        const SizedBox(width: AppSizes.spacingXs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ColorConstants.error.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusChip),
                          ),
                          child: Text(
                            'Urgent',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: ColorConstants.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconData() {
    switch (notification.category) {
      case 'loan':
        return AppIcons.loans.outline;
      case 'payment':
        return AppIcons.payments.outline;
      case 'membership':
        return AppIcons.members.outline;
      case 'savings':
        return AppIcons.savings.outline;
      case 'transaction':
        return notification.transactionType == 'savings_withdrawal'
            ? AppIcons.moneySend.outline
            : AppIcons.money.outline;
      default:
        return AppIcons.notifications.outline;
    }
  }

  Color _accentColor(ColorScheme colorScheme) {
    if (notification.isCritical) return ColorConstants.error;

    switch (notification.category) {
      case 'loan':
        return colorScheme.tertiary;
      case 'payment':
        return ColorConstants.accent;
      default:
        return colorScheme.primary;
    }
  }

  String _relativeTime(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    final local = timestamp.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}
