import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    final barColor = isDark ? ColorConstants.surfaceDark : Colors.white;
    final activeCircleColor = ColorConstants.brandGreen;
    final cutoutBgColor = theme.scaffoldBackgroundColor;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : ColorConstants.navyBlue.withValues(alpha: 0.65);

    return Container(
      decoration: BoxDecoration(
        color: cutoutBgColor,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : ColorConstants.navyBlue)
                .withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: CurvedNavigationBar(
          index: currentIndex.clamp(0, items.length - 1),
          height: 65.0,
          items: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = currentIndex == index;
            final isCenter = index == 2;

            final iconData = isSelected ? item.icon.bold : item.icon.outline;
            final iconColor = isSelected ? Colors.white : inactiveColor;
            final iconSize = isCenter ? 28.0 : 25.0;

            return Tooltip(
              key: ValueKey('nav_item_$index'),
              message: item.label,
              child: Semantics(
                label: item.label,
                selected: isSelected,
                button: true,
                child: Icon(
                  iconData,
                  size: iconSize,
                  color: iconColor,
                ),
              ),
            );
          }),
          color: barColor,
          buttonBackgroundColor: activeCircleColor,
          backgroundColor: cutoutBgColor,
          animationCurve: Curves.easeInOutCubic,
          animationDuration: const Duration(milliseconds: 320),
          onTap: onTap,
        ),
      ),
    );
  }
}