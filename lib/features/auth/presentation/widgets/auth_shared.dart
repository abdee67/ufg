import 'package:flutter/material.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_images.dart';
import 'package:ufg/core/constants/app_sizes.dart';

class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -110,
                right: -100,
                child: _circle(colorScheme.primary.withValues(alpha: 0.08), 285),
              ),
              Positioned(
                bottom: -135,
                left: -90,
                child: _circle(ColorConstants.navyBlue.withValues(alpha: 0.06), 265),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _circle(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class AuthLogoLockup extends StatelessWidget {
  const AuthLogoLockup({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Image.asset(AllImages().logo),
        ),
        const SizedBox(width: AppSizes.spacingS),
        Text(
          'Unity Finance',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(AppSizes.pageRadius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }
}

class AuthHeadline extends StatelessWidget {
  const AuthHeadline({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      text,
      style: theme.textTheme.displayLarge?.copyWith(
        color: theme.textTheme.bodyMedium?.color,
        fontSize: AppSizes.headingSize,
        height: 1.08,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class AuthLinkButton extends StatelessWidget {
  const AuthLinkButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}