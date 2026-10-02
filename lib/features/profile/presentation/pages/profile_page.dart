import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/app_card.dart';
import 'package:ufg/core/widgets/error_state.dart';
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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileEntity? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await getit<GetCurrentProfile>()();
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _errorMessage = failure.message;
      }),
      (profile) => setState(() {
        _isLoading = false;
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
        content: const Text('Are you sure you want to sign out of your account?'),
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
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(AppIcons.refresh.outline, size: AppSizes.iconM),
            tooltip: 'Refresh',
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _errorMessage != null
              ? ErrorState(
                  message: _errorMessage!,
                  onRetry: _loadProfile,
                )
              : RefreshIndicator(
                  color: colorScheme.primary,
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacingL,
                      vertical: AppSizes.spacingM,
                    ),
                    children: [
                      _buildHeroCard(theme, colorScheme, isDark),
                      const SizedBox(height: AppSizes.spacingL),
                      _buildMembershipStatusCard(theme, colorScheme, isDark),
                      const SizedBox(height: AppSizes.spacingL),
                      _buildPersonalDetailsCard(theme, colorScheme),
                      const SizedBox(height: AppSizes.spacingL),
                      _buildQuickActionsCard(theme, colorScheme),
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
                ),
    );
  }

  Widget _buildHeroCard(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    final profile = _profile;
    final fullName = profile?.fullName ?? 'Member User';
    final email = profile?.email ?? 'No email provided';
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
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 8),
                StatusChip(
                  label: profile?.status.name.toUpperCase() ?? 'ACTIVE',
                  tone: profile?.status == ProfileStatus.active
                      ? StatusTone.success
                      : StatusTone.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipStatusCard(
      ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return BlocBuilder<MembershipBloc, MembershipState>(
      builder: (context, state) {
        final isActive = state is MembershipStatusLoaded && state.isActiveMember;
        final hasApp = state is MembershipStatusLoaded && state.application != null;

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
                    ? 'Member #${state.member?.memberNumber ?? ''} - Full member privileges active.'
                    : hasApp
                        ? 'Your membership application is currently being reviewed.'
                        : 'Apply for official membership to access loans and higher savings returns.',
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
                      ? 'View Member ID & Details'
                      : hasApp
                          ? 'View Application Progress'
                          : 'Apply for Membership',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConstants.brandGreen,
                  side: const BorderSide(color: ColorConstants.brandGreen),
                  minimumSize: const Size.fromHeight(42),
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

    return AppCard(
      padding: AppSizes.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
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
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(ThemeData theme, ColorScheme colorScheme) {
    return AppCard(
      padding: 0,
      child: Column(
        children: [
          ListTile(
            leading: Icon(AppIcons.lock.outline, color: colorScheme.primary),
            title: const Text('Change Password'),
            trailing: Icon(AppIcons.forward.outline, size: AppSizes.iconS - 4),
            onTap: () => context.push(AppRoutes.changePasswordScreen),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(AppIcons.notifications.outline, color: colorScheme.primary),
            title: const Text('Notifications'),
            trailing: Icon(AppIcons.forward.outline, size: AppSizes.iconS - 4),
            onTap: () => context.push(AppRoutes.notification),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(AppIcons.settings.outline, color: colorScheme.primary),
            title: const Text('App Settings'),
            trailing: Icon(AppIcons.forward.outline, size: AppSizes.iconS - 4),
            onTap: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}
