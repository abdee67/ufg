import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/shared/custom_bottom_nav_bar.dart';

class DashboardWrapper extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardWrapper({super.key, required this.navigationShell});

  static const _items = [
    BottomNavItemConfig(
      label: 'Home',
      icon: AppIcons.home,
      route: AppRoutes.homeScreen,
    ),
    BottomNavItemConfig(
      label: 'Loans',
      icon: AppIcons.loans,
      route: AppRoutes.loans,
    ),
    BottomNavItemConfig(
      label: 'Savings',
      icon: AppIcons.add,
      route: AppRoutes.savings,
    ),
    BottomNavItemConfig(
      label: 'Transactions',
      icon: AppIcons.receiptItem,
      route: AppRoutes.savingsHistory,
    ),
    BottomNavItemConfig(
      label: 'Settings',
      icon: AppIcons.settings,
      route: AppRoutes.settings,
    ),
  ];

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      body: SizedBox.expand(child: navigationShell),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        items: _items,
      ),
    );
  }
}