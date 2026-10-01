import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/utils/app_state_notifier.dart';
import 'package:ufg/core/widgets/app_card.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _emailAlerts = true;
  bool _biometricsEnabled = false;

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(SignOutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingL,
          vertical: AppSizes.spacingM,
        ),
        children: [
          _buildSectionHeader('Appearance', theme),
          AppCard(
            padding: 0,
            child: Consumer<AppStateNotifier>(
              builder: (context, appState, _) {
                return SwitchListTile.adaptive(
                  value: appState.isDarkMode,
                  activeTrackColor: ColorConstants.brandGreen,
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    appState.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  secondary: Icon(
                    appState.isDarkMode ? AppIcons.moon.outline : AppIcons.sun.outline,
                    color: colorScheme.primary,
                  ),
                  onChanged: (val) {
                    appState.updateTheme(val);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          _buildSectionHeader('Notifications', theme),
          AppCard(
            padding: 0,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _pushNotifications,
                  activeTrackColor: ColorConstants.brandGreen,
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Alerts about savings and loans'),
                  secondary: Icon(
                    AppIcons.notifications.outline,
                    color: colorScheme.primary,
                  ),
                  onChanged: (val) {
                    setState(() => _pushNotifications = val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: _emailAlerts,
                  activeTrackColor: ColorConstants.brandGreen,
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Monthly statements and payment receipts'),
                  secondary: Icon(
                    AppIcons.mail.outline,
                    color: colorScheme.primary,
                  ),
                  onChanged: (val) {
                    setState(() => _emailAlerts = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          _buildSectionHeader('Security', theme),
          AppCard(
            padding: 0,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(AppIcons.lock.outline, color: colorScheme.primary),
                  title: const Text('Change Password'),
                  subtitle: const Text('Update account login credentials'),
                  trailing: Icon(AppIcons.forward.outline, size: AppSizes.iconS - 4),
                  onTap: () => context.push(AppRoutes.changePasswordScreen),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: _biometricsEnabled,
                  activeTrackColor: ColorConstants.brandGreen,
                  title: const Text('Biometric Login'),
                  subtitle: const Text('Use fingerprint or face recognition'),
                  secondary: Icon(
                    AppIcons.shield.outline,
                    color: colorScheme.primary,
                  ),
                  onChanged: (val) {
                    setState(() => _biometricsEnabled = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          _buildSectionHeader('About', theme),
          AppCard(
            padding: 0,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(AppIcons.info.outline, color: colorScheme.primary),
                  title: const Text('About Unity Finance Group'),
                  subtitle: const Text('Version 1.0.0+1'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(AppIcons.document.outline, color: colorScheme.primary),
                  title: const Text('Terms & Privacy Policy'),
                  trailing: Icon(AppIcons.forward.outline, size: AppSizes.iconS - 4),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spacingXl),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: Icon(AppIcons.logout.outline, size: AppSizes.iconS),
              label: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusButton),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingHero),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: AppSizes.spacingS,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
