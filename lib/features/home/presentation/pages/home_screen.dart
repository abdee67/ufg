import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/app_card.dart';
import 'package:ufg/core/widgets/section_header.dart';
import 'package:ufg/core/widgets/amount_text.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/core/widgets/error_state.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/home/presentation/bloc/home_bloc.dart';
import 'package:ufg/features/home/presentation/bloc/home_event.dart';
import 'package:ufg/features/home/presentation/bloc/home_state.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const FetchHomeData());
  }

  void _logout() {
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
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: colorScheme.primary,
          onRefresh: () async {
            context.read<HomeBloc>().add(const FetchHomeData(refresh: true));
          },
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) {
                return const Center(child: LoadingIndicator());
              }

              if (state is HomeLoadFailure) {
                return ErrorState(
                  message: state.message,
                  onRetry: () =>
                      context.read<HomeBloc>().add(const FetchHomeData()),
                );
              }

              if (state is HomeLoadSuccess) {
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacingL,
                        vertical: AppSizes.spacingM,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _StickyHeader(
                            userName: state.profile.fullName,
                            onLogoutTap: _logout,
                          ),
                          const SizedBox(height: AppSizes.spacingXl),
                          _SearchBar(
                            onTap: () => context.push(AppRoutes.searchScreen),
                          ),
                          const SizedBox(height: AppSizes.spacingXl),
                          _QuickActionsSection(),
                          const SizedBox(height: AppSizes.spacingXl),
                          _SavingsCard(
                            totalSavings:
                                state.savingsSummary?.totalSavings ?? 0,
                            nextDue: state
                                .savingsSummary?.currentObligation?.dueDate
                                .day
                                .toString(),
                            monthlyContribution: state.savingsSummary
                                    ?.currentObligation?.requiredAmount ??
                                0,
                          ).animate().fadeIn(duration: 400.ms).slideY(
                                begin: 0.1,
                                curve: Curves.easeOutQuad,
                              ),
                          const SizedBox(height: AppSizes.spacingXl),
                          _RecentActivitySection(
                            activities: state.recentActivity,
                          ),
                          const SizedBox(
                            height: AppSizes.spacingHero + AppSizes.spacingM,
                          ),
                        ]),
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _StickyHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onLogoutTap;

  const _StickyHeader({
    required this.userName,
    required this.onLogoutTap,
  });

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
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_getTimeGreeting()},',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  userName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _NotificationIcon(colorScheme: colorScheme),
                const SizedBox(width: AppSizes.spacingS),
                IconButton(
                  onPressed: onLogoutTap,
                  icon: Icon(
                    AppIcons.logout.outline,
                    color: colorScheme.primary,
                    size: AppSizes.iconM,
                  ),
                  tooltip: 'Logout',
                ),
              ],
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
}

class _NotificationIcon extends StatelessWidget {
  final ColorScheme colorScheme;
  const _NotificationIcon({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: IconButton(
            onPressed: () {},
            icon: Icon(
              AppIcons.notifications.outline,
              color: colorScheme.primary,
              size: AppSizes.iconM,
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ColorConstants.error,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingM,
          vertical: AppSizes.spacingM,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              AppIcons.search.outline,
              color: colorScheme.primary,
              size: AppSizes.iconS,
            ),
            const SizedBox(width: AppSizes.spacingS),
            Expanded(
              child: Text(
                'Search savings, loans...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            Icon(
              AppIcons.filter.outline,
              color: colorScheme.primary,
              size: AppSizes.iconS,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AppSizes.spacingM),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ActionItem(
              icon: AppIcons.savings.outline,
              label: 'Savings',
              color: ColorConstants.brandGreen,
              onTap: () => context.push(AppRoutes.savings),
            ),
            _ActionItem(
              icon: AppIcons.loans.outline,
              label: 'Loans',
              color: ColorConstants.navyBlue,
              onTap: () => context.push(AppRoutes.loans),
            ),
            _ActionItem(
              icon: AppIcons.payments.outline,
              label: 'Pay',
              color: Colors.orange,
              onTap: () {},
            ),
            _ActionItem(
              icon: AppIcons.members.outline,
              label: 'Members',
              color: Colors.purple,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
            ),
            child: Icon(icon, color: color, size: AppSizes.iconM),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SavingsCard extends StatelessWidget {
  final double totalSavings;
  final double monthlyContribution;
  final String? nextDue;

  const _SavingsCard({
    required this.totalSavings,
    required this.monthlyContribution,
    this.nextDue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBrand = ColorConstants.onBrand;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.navyBlue,
            ColorConstants.navyBlue.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.navyBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                'Total Balance',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: onBrand.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: onBrand.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.wallet.outline,
                  color: onBrand,
                  size: AppSizes.iconS,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AmountText(
            amount: totalSavings,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: onBrand,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'This Month',
                  value: monthlyContribution,
                  isAmount: true,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: onBrand.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _MetricItem(
                  label: 'Next Due',
                  value: nextDue ?? '-',
                  isAmount: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool isAmount;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.isAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBrand = ColorConstants.onBrand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: onBrand.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        if (isAmount)
          AmountText(
            amount: value as num,
            style: theme.textTheme.titleMedium?.copyWith(
              color: onBrand,
              fontWeight: FontWeight.bold,
            ),
          )
        else
          Text(
            value.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: onBrand,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  final List<dynamic> activities;

  const _RecentActivitySection({required this.activities});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Activity',
          trailing: 'View All',
          onTrailingTap: () => context.push(AppRoutes.savingsHistory),
        ),
        const SizedBox(height: AppSizes.spacingM),
        if (activities.isEmpty)
          AppCard(
            padding: AppSizes.spacingL,
            child: Center(
              child: Column(
                children: [
                  Icon(
                    AppIcons.walletEmpty.outline,
                    size: 48,
                    color: Theme.of(context).dividerColor,
                  ),
                  const SizedBox(height: 12),
                  const Text('No recent activity found'),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _ActivityTile(activity: activity);
            },
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final dynamic activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Based on SavingsHistoryItemEntity
    final isCredit = activity.isCredit;
    final color = isCredit ? ColorConstants.brandGreen : ColorConstants.error;

    return AppCard(
      padding: AppSizes.spacingM,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? AppIcons.arrowDown.outline : AppIcons.arrowUp.outline,
              color: color,
              size: AppSizes.iconS,
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description ?? 'Transaction',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  activity.timestamp.toString().split(' ')[0], // Simple date
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          AmountText(
            amount: activity.amount as num,
            signed: true,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
