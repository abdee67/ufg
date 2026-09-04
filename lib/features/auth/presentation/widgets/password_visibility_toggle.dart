import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_icons.dart';

class PasswordVisibilityToggle extends StatelessWidget {
  final bool visible;
  final VoidCallback onToggle;

  const PasswordVisibilityToggle({
    super.key,
    required this.visible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        visible ? AppIcons.eyeOff.outline : AppIcons.eye.outline,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      tooltip: visible ? 'Hide password' : 'Show password',
      onPressed: onToggle,
    );
  }
}