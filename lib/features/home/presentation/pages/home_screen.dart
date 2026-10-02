import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/utils/formatters.dart';
import 'package:ufg/core/widgets/app_card.dart';
import 'package:ufg/core/widgets/error_state.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/core/widgets/section_header.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/home/presentation/bloc/home_bloc.dart';
import 'package:ufg/features/home/presentation/bloc/home_event.dart';
import 'package:ufg/features/home/presentation/bloc/home_state.dart';
import 'package:ufg/features/loans/domain/entities/loan_entity.dart';
import 'package:ufg/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:ufg/features/savings/domain/entities/savings_history_item_entity.dart';
import 'package:ufg/features/savings/domain/entities/savings_summary_entity.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hideBalances = true;

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

  void _handlePayTap(BuildContext context, List<LoanEntity> activeLoans) {
    final activeLoan = activeLoans
            .where((loan) => loan.isActive || loan.isOverdue)
            .firstOrNull ??
        activeLoans.firstOrNull;

    if (activeLoan == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('You do not have an active loan to pay.'),
            backgroundColor: ColorConstants.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    context.push('${AppRoutes.loans}/repay/${activeLoan.id}');
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
                final summary = state.savingsSummary;
                final activeLoan = state.activeLoans
                        .where((loan) => loan.isActive || loan.isOverdue)
                        .firstOrNull ??
                    state.activeLoans.firstOrNull;

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
                          const SizedBox(height: AppSizes.spacingL),
                          _SearchBar(
                            onTap: () => context.push(AppRoutes.searchScreen),
                          ),
                          const SizedBox(height: AppSizes.spacingL),

                          // 1. Wallet / Balance Card with Hide/Show Privacy Toggle
                          _WalletBalanceCard(
                            savingsSummary: summary,
                            hideBalances: _hideBalances,
                            onTogglePrivacy: () {
                              setState(() {
                                _hideBalances = !_hideBalances;
                              });
                            },
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.08, curve: Curves.easeOutQuad),
                          const SizedBox(height: AppSizes.spacingXl),

                          // 2. High-Frequency Quick Actions Grid
                          _QuickActionsGrid(
                            onSendMoney: () =>
                                context.push(AppRoutes.savingsPayment),
                            onDeposit: () =>
                                context.push(AppRoutes.savingsPayment),
                            onApplyLoan: () =>
                                context.push(AppRoutes.loanApply),
                            onWithdraw: () =>
                                context.push(AppRoutes.savingsWithdraw),
                            onPayLoan: () =>
                                _handlePayTap(context, state.activeLoans),
                            onMembership: () =>
                                context.push(AppRoutes.membershipStatus),
                          ),
                          const SizedBox(height: AppSizes.spacingXl),

                          // 3. Dedicated Active Loan & Status Widget
                          _ActiveLoanSection(
                            activeLoan: activeLoan,
                            hideBalances: _hideBalances,
                          )
                              .animate()
                              .fadeIn(duration: 450.ms)
                              .slideY(begin: 0.08, curve: Curves.easeOutQuad),
                          const SizedBox(height: AppSizes.spacingXl),

                          // 4. Recent Transactions Mini-Feed
                          _RecentTransactionsSection(
                            activities: state.recentActivity,
                            hideBalances: _hideBalances,
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

  const _StickyHeader({required this.userName, required this.onLogoutTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.65);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
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
                userName.isNotEmpty ? userName : 'Member',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            const NotificationBadge(),
            const SizedBox(width: AppSizes.spacingS),
            IconButton(
              onPressed: onLogoutTap,
              icon: Icon(
                AppIcons.logout.outline,
                color: colorScheme.primary,
                size: AppSizes.iconM,
              ),
              tooltip: 'Sign Out',
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
                'Search savings, loans, transactions...',
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

/// 1. Wallet / Balance Card:
/// Prominently displays Total Savings, Share Capital (secured),
/// Deposits/Obligations, and Available Withdrawable Balance with privacy toggle.
class _WalletBalanceCard extends StatelessWidget {
  final SavingsSummaryEntity? savingsSummary;
  final bool hideBalances;
  final VoidCallback onTogglePrivacy;

  const _WalletBalanceCard({
    required this.savingsSummary,
    required this.hideBalances,
    required this.onTogglePrivacy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const onBrand = Colors.white;

    final totalSavings = savingsSummary?.totalSavings ?? 0.0;
    final shareCapital = savingsSummary?.securedSavings ?? 0.0;
    final availableWithdraw = savingsSummary?.availableToWithdraw ?? 0.0;
    final monthlyDeposit =
        savingsSummary?.currentObligation?.requiredAmount ?? 0.0;
    final dueDateDay = savingsSummary?.currentObligation?.dueDate.day;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E293B), // Slate 800
            Color(0xFF134E4A), // Deep Emerald Teal
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Label + Privacy Toggle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ColorConstants.brandGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF34D399),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TOTAL SAVINGS BALANCE',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: onBrand.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: onTogglePrivacy,
                icon: Icon(
                  hideBalances ? AppIcons.eyeOff.outline : AppIcons.eye.outline,
                  color: onBrand.withValues(alpha: 0.85),
                  size: AppSizes.iconM - 2,
                ),
                tooltip: hideBalances ? 'Show Balances' : 'Hide Balances',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main prominent figure
          Text(
            hideBalances ? 'ETB •••••••••' : Formatters.money(totalSavings),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: onBrand,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            color: onBrand.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 16),

          // 3-Column Financial Breakdown
          Row(
            children: [
              Expanded(
                child: _FinanceMetric(
                  label: 'Share Capital',
                  value: hideBalances
                      ? '••••••'
                      : Formatters.money(shareCapital, showSymbol: false),
                  prefix: hideBalances ? '' : 'ETB ',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: onBrand.withValues(alpha: 0.15),
              ),
              Expanded(
                child: _FinanceMetric(
                  label: 'Withdrawable',
                  value: hideBalances
                      ? '••••••'
                      : Formatters.money(availableWithdraw, showSymbol: false),
                  prefix: hideBalances ? '' : 'ETB ',
                  highlightColor: const Color(0xFF34D399),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: onBrand.withValues(alpha: 0.15),
              ),
              Expanded(
                child: _FinanceMetric(
                  label: dueDateDay != null ? 'Due Day $dueDateDay' : 'Deposit',
                  value: hideBalances
                      ? '••••••'
                      : Formatters.money(monthlyDeposit, showSymbol: false),
                  prefix: hideBalances ? '' : 'ETB ',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Action Pill Buttons inside the card
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.savingsPayment),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Deposit',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusButton),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.savingsWithdraw),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  label: const Text(
                    'Withdraw',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onBrand,
                    side: BorderSide(color: onBrand.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusButton),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final String prefix;
  final Color? highlightColor;

  const _FinanceMetric({
    required this.label,
    required this.value,
    this.prefix = '',
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    const onBrand = Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: onBrand.withValues(alpha: 0.65),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '$prefix$value',
          style: TextStyle(
            color: highlightColor ?? onBrand,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// 2. Quick Actions Grid:
/// High-frequency shortcuts: Send Money, Deposit/Contribute, Apply for Loan, Withdraw, Pay Loan, Members
class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onSendMoney;
  final VoidCallback onDeposit;
  final VoidCallback onApplyLoan;
  final VoidCallback onWithdraw;
  final VoidCallback onPayLoan;
  final VoidCallback onMembership;

  const _QuickActionsGrid({
    required this.onSendMoney,
    required this.onDeposit,
    required this.onApplyLoan,
    required this.onWithdraw,
    required this.onPayLoan,
    required this.onMembership,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AppSizes.spacingM),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.1,
          children: [
            _QuickActionTile(
              icon: AppIcons.moneySend.outline,
              label: 'Send Money',
              color: const Color(0xFF2563EB), // Vibrant Blue
              onTap: onSendMoney,
            ),
            _QuickActionTile(
              icon: AppIcons.add.outline,
              label: 'Deposit',
              color: ColorConstants.brandGreen, // Green
              onTap: onDeposit,
            ),
            _QuickActionTile(
              icon: AppIcons.loans.outline,
              label: 'Apply Loan',
              color: const Color(0xFF7C3AED), // Purple
              onTap: onApplyLoan,
            ),
            _QuickActionTile(
              icon: AppIcons.wallet.outline,
              label: 'Withdraw',
              color: const Color(0xFFD97706), // Amber
              onTap: onWithdraw,
            ),
            _QuickActionTile(
              icon: AppIcons.payments.outline,
              label: 'Pay Loan',
              color: const Color(0xFFDC2626), // Coral Red
              onTap: onPayLoan,
            ),
            _QuickActionTile(
              icon: AppIcons.members.outline,
              label: 'Membership',
              color: const Color(0xFF0D9488), // Teal
              onTap: onMembership,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? color.withValues(alpha: 0.18)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                ),
                child: Icon(icon, color: color, size: AppSizes.iconM - 2),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
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

/// 3. Active Loans & Status Card:
/// Shows active loan balance, next installment due date, amount, and quick Pay Loan button.
class _ActiveLoanSection extends StatelessWidget {
  final LoanEntity? activeLoan;
  final bool hideBalances;

  const _ActiveLoanSection({
    required this.activeLoan,
    required this.hideBalances,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (activeLoan == null) {
      // Clean CTA card when user has no active loan
      return AppCard(
        padding: AppSizes.spacingL,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.navyBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.loans.outline,
                color: ColorConstants.navyBlue,
                size: AppSizes.iconM,
              ),
            ),
            const SizedBox(width: AppSizes.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Funding For Growth?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Access affordable member loans with instant processing.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.spacingS),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.loanApply),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusButton),
                ),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      );
    }

    final loan = activeLoan!;
    final bool isOverdue = loan.isOverdue;
    final statusColor = isOverdue ? ColorConstants.error : ColorConstants.brandGreen;
    final progress = loan.repaymentProgress;
    final dueDateStr = loan.maturityDate != null
        ? DateFormat('dd MMM yyyy').format(loan.maturityDate!)
        : 'Ongoing';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Active Loan',
          trailing: 'Details',
          onTrailingTap: () =>
              context.push('${AppRoutes.loans}/detail/${loan.id}'),
        ),
        const SizedBox(height: AppSizes.spacingXs),
        AppCard(
          padding: AppSizes.spacingL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Loan number + Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppIcons.loans.outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loan #${loan.loanNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      loan.status.name.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Outstanding balance
              Text(
                'Remaining Outstanding Balance',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hideBalances
                    ? 'ETB ••••••••'
                    : Formatters.money(loan.outstandingBase),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : ColorConstants.navyBlue,
                ),
              ),
              const SizedBox(height: 14),

              // Repayment progress
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  color: ColorConstants.brandGreen,
                  backgroundColor: theme.dividerColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toInt()}% Repaid',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.brandGreen,
                    ),
                  ),
                  Text(
                    'Due: $dueDateStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Quick Pay Loan Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('${AppRoutes.loans}/repay/${loan.id}'),
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: const Text(
                    'Pay Loan Now',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusButton),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 4. Recent Transactions:
/// A mini feed showing the last 3-5 deposits, share contributions, or transfers with status tags.
class _RecentTransactionsSection extends StatelessWidget {
  final List<SavingsHistoryItemEntity> activities;
  final bool hideBalances;

  const _RecentTransactionsSection({
    required this.activities,
    required this.hideBalances,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayItems = activities.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Transactions',
          trailing: 'See All',
          onTrailingTap: () => context.go(AppRoutes.savingsHistory),
        ),
        const SizedBox(height: AppSizes.spacingM),
        if (displayItems.isEmpty)
          AppCard(
            padding: AppSizes.spacingL,
            child: Center(
              child: Column(
                children: [
                  Icon(
                    AppIcons.walletEmpty.outline,
                    size: 44,
                    color: Theme.of(context).dividerColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No recent transactions found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = displayItems[index];
              return _TransactionMiniTile(
                item: item,
                hideBalances: hideBalances,
              );
            },
          ),
      ],
    );
  }
}

class _TransactionMiniTile extends StatelessWidget {
  final SavingsHistoryItemEntity item;
  final bool hideBalances;

  const _TransactionMiniTile({
    required this.item,
    required this.hideBalances,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormatter = DateFormat('dd MMM, hh:mm a');

    final bool isCredit = item.isCredit;
    final color = isCredit ? ColorConstants.brandGreen : ColorConstants.error;
    final statusLower = item.status.toLowerCase();
    final bool isSuccess =
        statusLower == 'completed' || statusLower == 'posted' || statusLower == 'paid';
    final bool isPending = statusLower == 'pending';

    final Color statusTagColor = isSuccess
        ? ColorConstants.brandGreen
        : isPending
            ? const Color(0xFFD97706)
            : ColorConstants.error;

    return AppCard(
      padding: AppSizes.spacingM,
      child: Row(
        children: [
          // Direction indicator icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.16)
                  : color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? AppIcons.arrowDown.outline : AppIcons.arrowUp.outline,
              color: color,
              size: AppSizes.iconS,
            ),
          ),
          const SizedBox(width: AppSizes.spacingM),

          // Title & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description.isNotEmpty
                      ? item.description
                      : (isCredit ? 'Deposit' : 'Withdrawal'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormatter.format(item.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Amount & Status Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hideBalances
                    ? (isCredit ? '+ETB ••••' : '-ETB ••••')
                    : Formatters.signedMoney(isCredit ? item.amount : -item.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusTagColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    color: statusTagColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
