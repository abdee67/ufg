import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';

class BottomNavItemConfig {
  const BottomNavItemConfig({
    required this.label,
    required this.icon,
    this.route,
  });

  final String label;
  final AppIconPair icon;
  final String? route;
}

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItemConfig> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppSizes.navBarHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _NavItem(item: items[i], index: i, isSelected: currentIndex == i, onTap: onTap)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final BottomNavItemConfig item;
  final int index;
  final bool isSelected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Semantics(
      label: item.label,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: () => onTap(index),
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? item.icon.bold : item.icon.outline,
                size: AppSizes.iconM,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: AppSizes.spacingXxs),
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: AppSizes.spacingXxs),
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: ColorConstants.brandGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}