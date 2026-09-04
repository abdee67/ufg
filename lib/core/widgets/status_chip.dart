import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_sizes.dart';

enum StatusTone { success, warning, error, info, neutral }

class StatusChipColors {
  const StatusChipColors({required this.foreground, required this.background});

  final Color foreground;
  final Color background;
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  static StatusChipColors colorsOf(BuildContext context, StatusTone tone) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (tone) {
      case StatusTone.success:
        return StatusChipColors(
          foreground: isDark ? ColorConstants.textPrimaryDark : ColorConstants.success,
          background: isDark
              ? ColorConstants.successSubtleDark
              : ColorConstants.successSubtle,
        );
      case StatusTone.warning:
        return StatusChipColors(
          foreground: isDark ? ColorConstants.warningDark : ColorConstants.warning,
          background: isDark
              ? ColorConstants.warningSubtleDark
              : ColorConstants.warningSubtle,
        );
      case StatusTone.error:
        return StatusChipColors(
          foreground: isDark ? ColorConstants.textPrimaryDark : ColorConstants.error,
          background: isDark
              ? ColorConstants.errorSubtleDark
              : ColorConstants.errorSubtle,
        );
      case StatusTone.info:
        return StatusChipColors(
          foreground: isDark ? ColorConstants.infoDark : ColorConstants.info,
          background: isDark
              ? ColorConstants.infoSubtleDark
              : ColorConstants.infoSubtle,
        );
      case StatusTone.neutral:
        return StatusChipColors(
          foreground: theme.textTheme.bodyMedium!.color ?? theme.colorScheme.onSurface,
          background: isDark
              ? ColorConstants.neutralSubtleDark
              : ColorConstants.neutralSubtle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context, tone);

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingS,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppSizes.radiusChip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSizes.iconXs, color: colors.foreground),
              const SizedBox(width: AppSizes.spacingXxs),
            ],
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}