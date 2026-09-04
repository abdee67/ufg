import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(title, style: AppTextStyles.sectionTitle(context)),
          ),
          if (trailing != null)
            TextButton(
              onPressed: onTrailingTap,
              child: Text(
                trailing!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}