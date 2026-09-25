import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/features/auth/presentation/widgets/auth_shared.dart';

/// Password recovery is intentionally handled by a database administrator.
/// This screen never collects identity information and never initiates a reset.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AuthBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => context.go(AppRoutes.loginScreen),
                      icon: Icon(AppIcons.back.outline),
                      tooltip: 'Back to sign in',
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                    const AuthLogoLockup(),
                    const SizedBox(height: 48),
                    const AuthHeadline(text: 'Need help with\nyour password?'),
                    const SizedBox(height: AppSizes.sectionGap),
                    AuthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            AppIcons.info.outline,
                            color: theme.colorScheme.primary,
                            size: 30,
                          ),
                          const SizedBox(height: AppSizes.spacingM),
                          Text(
                            'Password recovery is handled by a Unity Finance database administrator after your identity is verified.',
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSizes.spacingM),
                          Text(
                            'They will provide a temporary password. Sign in with it, then create a new password when prompted.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
