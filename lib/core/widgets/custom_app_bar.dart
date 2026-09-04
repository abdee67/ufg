import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_sizes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    required this.fallbackRoute,
  });

  final String title;
  final List<Widget>? actions;
  final String fallbackRoute;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: IconButton(
        icon: Icon(AppIcons.back.outline, size: AppSizes.iconM),
        onPressed: () => _pop(context),
        tooltip: 'Back',
      ),
      actions: actions,
    );
  }
}