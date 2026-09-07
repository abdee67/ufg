import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/app_card.dart';
import 'package:ufg/core/widgets/section_header.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AuthBloc authBloc;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    Future.microtask(_refreshHomeData);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _logout() {
    // Show logout confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              authBloc.add(AuthLoggedOut() as AuthEvent);
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

  Future<void> _refreshHomeData() async {
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: colorScheme.primary,
          backgroundColor: colorScheme.surface,
          onRefresh: _refreshHomeData,
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.spacingL,
                        AppSizes.spacingM,
                        AppSizes.spacingL,
                        AppSizes.spacingHero + AppSizes.spacingM,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const _StickyHeader(),
                          const SizedBox(height: AppSizes.spacingXl),
                          _SearchBar(
                            onTap: () =>
                                context.push(AppRoutes.searchScreen),
                          ),
                          const SizedBox(height: AppSizes.spacingXl),
                          const _FinanceOverviewSection(),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StickyHeader extends StatelessWidget {
  const _StickyHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.65);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Unity Finance',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        AppIcons.notifications.outline,
                        color: colorScheme.primary,
                        size: AppSizes.iconM,
                      ),
                      splashRadius: 20,
                      tooltip: 'Notifications',
                    ),
                    Positioned(
                      top: 8,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: ColorConstants.brandGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSizes.spacingXxs),
                IconButton(
                  onPressed: () => _logout(),
                  icon: Icon(
                    AppIcons.settings.outline,
                    color: colorScheme.primary,
                    size: AppSizes.iconM,
                  ),
                  splashRadius: 20,
                  tooltip: 'Settings',
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTimeIcon(),
              color: secondaryText,
              size: AppSizes.iconS - 2,
            ),
            const SizedBox(width: 6),
            Text(
              'Good ${_getTimeGreeting()}',
              style: TextStyle(
                color: secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  IconData _getTimeIcon() {
    final hour = DateTime.now().hour;
    if (hour < 17) return AppIcons.sun.outline;
    return AppIcons.moon.outline;
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      elevation: 2,
      shadowColor: colorScheme.shadow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingM,
            vertical: AppSizes.spacingM,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.spacingXs),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                ),
                child: Icon(
                  AppIcons.search.outline,
                  color: colorScheme.primary,
                  size: AppSizes.iconS,
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
              Expanded(
                child: Text(
                  'Search savings, loans, or transactions...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingS,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.filter.outline,
                      color: colorScheme.primary,
                      size: AppSizes.iconXs,
                    ),
                    const SizedBox(width: AppSizes.spacingXxs),
                    Text(
                      'Filters',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceOverviewSection extends StatelessWidget {
  const _FinanceOverviewSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AppSizes.spacingS),
        Row(
          children: [
            _ActionCard(
              icon: AppIcons.savings.outline,
              label: 'Savings',
              color: ColorConstants.brandGreen,
              onTap: () => context.push(AppRoutes.savings),
            ),
            const SizedBox(width: AppSizes.spacingS),
            _ActionCard(
              icon: AppIcons.loans.outline,
              label: 'Loans',
              color: ColorConstants.navyBlue,
              onTap: () => context.push(AppRoutes.loans),
            ),
            const SizedBox(width: AppSizes.spacingS),
            _ActionCard(
              icon: AppIcons.payments.outline,
              label: 'Payments',
              color: colorScheme.primary,
              onTap: () {},
            ),
            const SizedBox(width: AppSizes.spacingS),
            _ActionCard(
              icon: AppIcons.members.outline,
              label: 'Members',
              color: ColorConstants.navyBlue,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingXl),
        InkWell(
          onTap: () => context.push(AppRoutes.savings),
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          child: const _SavingsCard(),
        ),
        const SizedBox(height: AppSizes.spacingM),
        const _RecentActivityCard(),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.spacingM,
            horizontal: 6,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusChip),
                ),
                child: Icon(icon, color: color, size: AppSizes.iconM - 2),
              ),
              const SizedBox(height: AppSizes.spacingXs),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard();

  @override
  Widget build(BuildContext context) {
    final onGradient = ColorConstants.onBrand;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.navGradientStart,
            ColorConstants.navGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.navyBlue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Savings',
                style: TextStyle(
                  color: onGradient,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                AppIcons.savings.outline,
                color: onGradient.withValues(alpha: 0.9),
                size: AppSizes.iconS,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingXs),
          Text(
            'ETB 0.00',
            style: TextStyle(
              color: onGradient,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Row(
            children: [
              _MetricChip(label: 'This month', value: 'ETB 0.00'),
              const SizedBox(width: AppSizes.spacingS),
              _MetricChip(label: 'Next due', value: '12th'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final onGradient = ColorConstants.onBrand;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacingS),
        decoration: BoxDecoration(
          color: onGradient.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSizes.radiusChip),
          border: Border.all(
            color: onGradient.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: onGradient.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXxs),
            Text(
              value,
              style: TextStyle(
                color: onGradient,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recent Activity',
            trailing: 'View all',
            onTrailingTap: () {},
          ),
          const SizedBox(height: AppSizes.spacingS),
          _ActivityRow(
            icon: AppIcons.savings.outline,
            title: 'Monthly savings',
            subtitle: 'Pending contribution',
            amount: 'ETB 2,000',
            color: ColorConstants.brandGreen,
          ),
          const Divider(height: AppSizes.spacingXl),
          _ActivityRow(
            icon: AppIcons.walletEmpty.outline,
            title: 'No recent transactions',
            subtitle: 'Activity will appear here',
            amount: '',
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;

  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusChip),
          ),
          child: Icon(icon, color: color, size: AppSizes.iconS),
        ),
        const SizedBox(width: AppSizes.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        if (amount.isNotEmpty)
          Text(
            amount,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
      ],
    );
  }
}