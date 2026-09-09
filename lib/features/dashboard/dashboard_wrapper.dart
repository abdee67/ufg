import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/shared/custom_bottom_nav_bar.dart';

class DashboardWrapper extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardWrapper({super.key, required this.navigationShell});

  static const _items = [
    BottomNavItemConfig(label: 'Home', icon: AppIcons.home),
    BottomNavItemConfig(label: 'Savings', icon: AppIcons.savings, route: AppRoutes.savings),
    BottomNavItemConfig(label: 'Loans', icon: AppIcons.loans, route: AppRoutes.loans),

    BottomNavItemConfig(label: 'Membership', icon: AppIcons.members, route: AppRoutes.membershipStatus),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == 0) {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
      return;
    }
    final route = _items[index].route;
    if (route != null) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(child: navigationShell),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        items: _items,
      ),
    );
  }
}