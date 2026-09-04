import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_sizes.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    required this.theme,
    required this.title,
    required this.description,
  });

  final ThemeData theme;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.spacingXl),
        gradient: const LinearGradient(
          colors: [
            ColorConstants.navGradientStart,
            ColorConstants.navGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: ColorConstants.onBrand,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXs),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ColorConstants.onBrand.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}