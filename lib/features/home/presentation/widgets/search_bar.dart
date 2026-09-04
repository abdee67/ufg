import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Search savings, loans, or transactions...',
          prefixIcon: Icon(
            AppIcons.search.outline,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSheet),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSheet),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: AppSizes.spacingL,
          ),
        ),
        onTap: () => context.push(AppRoutes.searchScreen),
      ),
    );
  }
}