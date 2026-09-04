import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/app_card.dart';
import 'package:ufg/core/widgets/error_state.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/core/widgets/section_header.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_event.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_state.dart';
import 'package:ufg/features/savings/presentation/widgets/monthly_obligation_card.dart';
import 'package:ufg/features/savings/presentation/widgets/savings_balance_card.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    context.read<SavingsBloc>().add(LoadSavingsSummaryRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Savings'),
        leading: IconButton(
          icon: Icon(AppIcons.back.outline, size: AppSizes.iconM),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.homeScreen);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(AppIcons.history.outline, size: AppSizes.iconM),
            tooltip: 'Savings History',
            onPressed: () => context.push(AppRoutes.savingsHistory),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: BlocConsumer<SavingsBloc, SavingsState>(
          listener: (context, state) {
            if (state is SavingsFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SavingsLoading) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  LoadingIndicator(),
                ],
              );
            }

            if (state is SavingsSummaryLoaded) {
              final summary = state.summary;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingL,
                  vertical: AppSizes.spacingM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SavingsBalanceCard(
                      totalSavings: summary.totalSavings,
                      availableToWithdraw: summary.availableToWithdraw,
                      securedSavings: summary.securedSavings,
                      onContributeTap: () =>
                          context.push(AppRoutes.savingsPayment),
                      onWithdrawTap: () =>
                          context.push(AppRoutes.savingsWithdraw),
                    ),
                    const SizedBox(height: AppSizes.spacingXl),
                    SectionHeader(
                      title: 'Current Obligation',
                      trailing: 'View All Obligations',
                      onTrailingTap: () =>
                          context.push(AppRoutes.savingsObligations),
                    ),
                    const SizedBox(height: AppSizes.spacingXs),
                    if (summary.currentObligation != null)
                      MonthlyObligationCard(
                        obligation: summary.currentObligation!,
                        onPayTap: () => context.push(
                          AppRoutes.savingsPayment,
                          extra: summary.currentObligation,
                        ),
                      )
                    else
                      AppCard(
                        padding: AppSizes.compactCardPadding,
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.check.outline,
                              color: ColorConstants.success,
                              size: AppSizes.iconS,
                            ),
                            const SizedBox(width: AppSizes.spacingS),
                            const Expanded(
                              child: Text(
                                'No active obligation pending for this month.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSizes.spacingXl),
                    SectionHeader(title: 'Quick Shortcuts'),
                    const SizedBox(height: AppSizes.spacingS),
                    Row(
                      children: [
                        _ShortcutCard(
                          icon: AppIcons.receiptItem.outline,
                          title: 'Withdrawal Requests',
                          subtitle: 'Track review status',
                          onTap: () =>
                              context.push(AppRoutes.savingsWithdrawals),
                        ),
                        const SizedBox(width: AppSizes.spacingS),
                        _ShortcutCard(
                          icon: AppIcons.history.outline,
                          title: 'Transaction Log',
                          subtitle: 'View ledger records',
                          onTap: () =>
                              context.push(AppRoutes.savingsHistory),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacingHero),
                  ],
                ),
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ErrorState(
                  message: 'Failed to load savings summary.',
                  onRetry: _refreshData,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: AppCard(
        padding: AppSizes.spacingS + 2,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.spacingXs),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colorScheme.primary, size: AppSizes.iconS),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}