import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/utils/app_state_notifier.dart';
import 'package:ufg/core/widgets/app_card.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/core/widgets/meta_row.dart';
import 'package:ufg/core/widgets/status_chip.dart';
import 'package:ufg/features/auth/domain/entities/profile_entity.dart';
import 'package:ufg/features/auth/domain/usecases/get_current_profile.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_bloc.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_event.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_state.dart';
import 'package:ufg/injection_container.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ProfileEntity? _profile;
  bool _isLoadingProfile = true;

  bool _pushNotifications = true;
  bool _emailAlerts = true;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    final result = await getit<GetCurrentProfile>()();
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isLoadingProfile = false;
      }),
      (profile) => setState(() {
        _isLoadingProfile = false;
        _profile = profile;
      }),
    );

    context.read<MembershipBloc>().add(LoadMembershipStatusRequested());
  }

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

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: Icon(AppIcons.refresh.outline, size: AppSizes.iconM),
            tooltip: 'Refresh Profile',
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _isLoadingProfile && _profile == null
          ? const Center(child: LoadingIndicator())
          : RefreshIndicator(
              color: colorScheme.primary,
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingL,
                  vertical: AppSizes.spacingM,
                ),
                children: [
                  // ================= 1. Detailed Profile Hero Card =================
                  _buildProfileHeroCard(theme, colorScheme, isDark),
                  const SizedBox(height: AppSizes.spacingL),

                  // ================= 2. Membership Status & ID Card =================
                  _buildMembershipCard(theme, colorScheme),
                  const SizedBox(height: AppSizes.spacingL),

                  // ================= 3. Personal Details =================
                  _buildPersonalDetailsCard(theme, colorScheme),
                  const SizedBox(height: AppSizes.spacingXl),

                  // ================= 4. Appearance (Dark Mode) =================
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
                            appState.isDarkMode
                                ? 'Dark theme enabled'
                                : 'Light theme enabled',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          secondary: Icon(
                            appState.isDarkMode
                                ? AppIcons.moon.outline
                                : AppIcons.sun.outline,
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

                  // ================= 5. Notifications =================
                  _buildSectionHeader('Notifications', theme),
                  AppCard(
                    padding: 0,
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: _pushNotifications,
                          activeTrackColor: ColorConstants.brandGreen,
                          title: const Text('Push Notifications'),
                          subtitle: const Text(
                            'Alerts about savings, loans, and updates',
                          ),
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
                          subtitle: const Text(
                            'Monthly statements and transaction receipts',
                          ),
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

                  // ================= 6. Security =================
                  _buildSectionHeader('Security', theme),
                  AppCard(
                    padding: 0,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            AppIcons.lock.outline,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Change Password'),
                          subtitle: const Text(
                            'Update account login credentials',
                          ),
                          trailing: Icon(
                            AppIcons.forward.outline,
                            size: AppSizes.iconS - 4,
                          ),
                          onTap: () =>
                              context.push(AppRoutes.changePasswordScreen),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: _biometricsEnabled,
                          activeTrackColor: ColorConstants.brandGreen,
                          title: const Text('Biometric Login'),
                          subtitle: const Text(
                            'Use fingerprint or Face ID for fast login',
                          ),
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

                  // ================= 7. About & Legal =================
                  _buildSectionHeader('About', theme),
                  AppCard(
                    padding: 0,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            AppIcons.info.outline,
                            color: colorScheme.primary,
                          ),
                          title: const Text('About Unity Finance Group'),
                          subtitle: const Text('Version 1.0.0+1'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            AppIcons.document.outline,
                            color: colorScheme.primary,
                          ),
                          title: const Text('Terms & Privacy Policy'),
                          trailing: Icon(
                            AppIcons.forward.outline,
                            size: AppSizes.iconS - 4,
                          ),
                          onTap: () => context.push(AppRoutes.privacyPolicy),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXl),

                  // ================= 8. Sign Out =================
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.buttonHeight,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: Icon(AppIcons.logout.outline, size: AppSizes.iconS),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusButton,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingHero),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSizes.spacingXs,
        bottom: AppSizes.spacingS,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileHeroCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final profile = _profile;
    final fullName = profile?.fullName ?? 'Valued Member';
    final email = profile?.email ?? (profile?.phone ?? 'Member Account');
    final initials = _getInitials(fullName);

    return AppCard(
      padding: AppSizes.cardPadding,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  ColorConstants.navGradientStart,
                  ColorConstants.navGradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.brandGreen.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusChip(
                      label: profile?.status.name.toUpperCase() ?? 'ACTIVE',
                      tone: profile?.status == ProfileStatus.active
                          ? StatusTone.success
                          : StatusTone.warning,
                    ),
                    if (profile != null && profile.isMember) ...[
                      const SizedBox(width: 6),
                      const StatusChip(
                        label: 'MEMBER',
                        tone: StatusTone.neutral,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(ThemeData theme, ColorScheme colorScheme) {
    return BlocBuilder<MembershipBloc, MembershipState>(
      builder: (context, state) {
        final isActive =
            state is MembershipStatusLoaded && state.isActiveMember;
        final hasApp =
            state is MembershipStatusLoaded && state.application != null;

        return AppCard(
          padding: AppSizes.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppIcons.members.outline,
                        color: ColorConstants.brandGreen,
                        size: AppSizes.iconM,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Membership Status',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  StatusChip(
                    label: isActive
                        ? 'ACTIVE'
                        : hasApp
                        ? 'PENDING'
                        : 'NON-MEMBER',
                    tone: isActive
                        ? StatusTone.success
                        : hasApp
                        ? StatusTone.warning
                        : StatusTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingM),
              Text(
                isActive
                    ? 'Member #${state.member?.memberNumber ?? ''} • Full access to high-yield savings and loans.'
                    : hasApp
                    ? 'Your membership application is currently under review.'
                    : 'Apply for membership to unlock higher returns and member-only loans.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),
              OutlinedButton.icon(
                onPressed: () {
                  if (isActive || hasApp) {
                    context.push(AppRoutes.membershipStatus);
                  } else {
                    context.push(AppRoutes.membershipApply);
                  }
                },
                icon: Icon(
                  isActive ? AppIcons.shield.outline : AppIcons.forward.outline,
                  size: AppSizes.iconS,
                ),
                label: Text(
                  isActive
                      ? 'View Member ID & Status'
                      : hasApp
                      ? 'Check Application Progress'
                      : 'Apply for Membership',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConstants.brandGreen,
                  side: const BorderSide(color: ColorConstants.brandGreen),
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalDetailsCard(ThemeData theme, ColorScheme colorScheme) {
    final profile = _profile;
    final phone = profile?.phone ?? 'Not provided';
    final address = profile?.address ?? 'Not provided';
    final dob = profile?.dateOfBirth != null
        ? DateFormat('dd MMM yyyy').format(profile!.dateOfBirth!)
        : 'Not provided';
    final memberSince = profile != null
        ? DateFormat('MMM yyyy').format(profile.createdAt)
        : 'Not provided';

    return AppCard(
      padding: AppSizes.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          MetaRow(
            icon: AppIcons.phone.outline,
            label: 'Phone Number',
            value: phone,
          ),
          const Divider(height: 20),
          MetaRow(
            icon: AppIcons.category.outline,
            label: 'Residential Address',
            value: address,
          ),
          const Divider(height: 20),
          MetaRow(
            icon: AppIcons.calendar.outline,
            label: 'Date of Birth',
            value: dob,
          ),
          const Divider(height: 20),
          MetaRow(
            icon: AppIcons.clock.outline,
            label: 'Member Since',
            value: memberSince,
          ),
        ],
      ),
    );
  }
}
