import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_sizes.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSizes.cardPadding,
    this.onTap,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final double padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppSizes.radiusCard);

    // Use Material with the actual card color so child ListTiles / InkWells
    // have an opaque Material ancestor for visible ink splashes.
    Widget content = Padding(padding: EdgeInsets.all(padding), child: child);

    if (onTap != null) {
      content = InkWell(onTap: onTap, borderRadius: radius, child: content);
    }

    return Padding(
      padding: margin,
      child: Material(
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}
