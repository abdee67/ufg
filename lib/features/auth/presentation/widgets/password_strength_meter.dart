import 'package:flutter/material.dart';

class PasswordStrengthMeter extends StatelessWidget {
  final String password;
  const PasswordStrengthMeter({super.key, required this.password});

  int _calculateStrength() {
    if (password.length < 6) return 1;
    if (password.length < 10) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = _calculateStrength();

    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 5,
            decoration: BoxDecoration(
              color: i < strength
                  ? theme.colorScheme.primary
                  : theme.dividerColor,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        );
      }),
    );
  }
}