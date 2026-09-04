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

    final container = Container(
      margin: margin,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: radius,
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: container),
    );
  }
}