import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/custom_app_bar.dart';
import 'package:ufg/core/widgets/error_state.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/features/loans/domain/entities/loan_application_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_entity.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_bloc.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_event.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_state.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_status_chip.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_summary_card.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    context.read<LoanBloc>().add(LoadLoansDashboardRequested());
  }

  void _showSnackBar(
    BuildContext scaffoldContext,
    String message,
    Color backgroundColor, {
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(scaffoldContext);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Loans',
        fallbackRoute: AppRoutes.homeScreen,
        actions: [
          IconButton(
            icon: Icon(AppIcons.refresh.outline, size: AppSizes.iconM),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: Builder(
        builder: (scaffoldContext) {
          return BlocListener<LoanBloc, LoanState>(
            listenWhen: (previous, current) =>
                current is LoanActionSuccess || current is LoanFailure,
            listener: (context, state) {
              if (state is LoanActionSuccess) {
                _showSnackBar(
                    scaffoldContext, state.message, ColorConstants.success);
                _refresh();
              } else if (state is LoanFailure) {
                _showSnackBar(
                    scaffoldContext, state.message, ColorConstants.error);
              }
            },
            child: BlocBuilder<LoanBloc, LoanState>(
              builder: (context, state) {
                if (state is LoanLoading) {
                  return const Center(child: LoadingIndicator());
                }

                if (state is LoanFailure) {
                  return ErrorState(
                    title: 'Unable to load loans',
                    message: state.message,
                    onRetry: _refresh,
                  );
                }

                if (state is LoansDashboardLoaded) {
                  return _LoansDashboardBody(
                    state: state,
                    onRefresh: _refresh,
                    showSnackBar: (msg, color, {action}) =>
                        _showSnackBar(scaffoldContext, msg, color,
                            action: action),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }
}

class _LoansDashboardBody extends StatelessWidget {
  final LoansDashboardLoaded state;
  final VoidCallback onRefresh;
  final void Function(String, Color, {SnackBarAction? action}) showSnackBar;

  const _LoansDashboardBody({
    required this.state,
    required this.onRefresh,
    required this.showSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormatter = NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 2,
    );

    final activeLoan = state.primaryActiveLoan;
    final applications = state.applications;
    final pendingGuarantors = state.pendingGuarantorRequests;
    final pendingApplication = applications
        .where((a) => a.isPending)
        .firstOrNull;
    final hasActiveLoan = activeLoan != null;
    final hasPendingApplication = pendingApplication != null;
    final canApply = !hasActiveLoan && !hasPendingApplication;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          if (pendingGuarantors.isNotEmpty) ...[
            _buildGuarantorBanner(context, pendingGuarantors.length),
            const SizedBox(height: AppSizes.spacingM),
          ],
          if (activeLoan != null) ...[
            LoanSummaryCard(
              loan: activeLoan,
              onRepayTap: () =>
                  context.push('${AppRoutes.loans}/repay/${activeLoan.id}'),
              onDetailsTap: () =>
                  context.push('${AppRoutes.loans}/detail/${activeLoan.id}'),
            ),
          ] else if (pendingApplication != null) ...[
            _buildPendingApplicationBanner(context, pendingApplication),
          ] else ...[
            _buildNoActiveLoanBanner(context),
          ],
          const SizedBox(height: AppSizes.spacingL),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  context,
                  title: 'Apply for Loan',
                  icon: canApply ? AppIcons.add.outline : AppIcons.lock.outline,
                  color: canApply ? colorScheme.primary : theme.hintColor,
                  subtitle: hasActiveLoan
                      ? 'Loan Active'
                      : (hasPendingApplication ? 'In Progress' : null),
                  onTap: () => _onApplyTap(
                    context,
                    hasActiveLoan: hasActiveLoan,
                    hasPendingApplication: hasPendingApplication,
                    activeLoan: activeLoan,
                    pendingApplication: pendingApplication,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
              Expanded(
                child: _actionButton(
                  context,
                  title: 'Guarantor Requests',
                  icon: AppIcons.shield.outline,
                  color: ColorConstants.warning,
                  badgeCount: pendingGuarantors.length,
                  onTap: () => context.push('${AppRoutes.loans}/guarantors'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Applications',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (applications.isNotEmpty)
                Text(
                  '${applications.length} Total',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          if (applications.isEmpty)
            _buildEmptyApplicationsState(theme)
          else
            ...applications.map(
              (app) => _buildApplicationTile(context, app, currencyFormatter),
            ),
        ],
      ),
    );
  }

  void _onApplyTap(
    BuildContext context, {
    required bool hasActiveLoan,
    required bool hasPendingApplication,
    required LoanEntity? activeLoan,
    required LoanApplicationEntity? pendingApplication,
  }) {
    if (hasActiveLoan) {
      showSnackBar(
        'You have an active loan. Full repayment is required before applying for a new loan.',
        ColorConstants.warning,
        action: SnackBarAction(
          label: 'Repay',
          textColor: Colors.white,
          onPressed: () =>
              context.push('${AppRoutes.loans}/repay/${activeLoan!.id}'),
        ),
      );
    } else if (hasPendingApplication) {
      showSnackBar(
        'Application #${pendingApplication!.applicationNumber} is in progress. Multiple loan applications are not permitted.',
        ColorConstants.warning,
        action: SnackBarAction(
          label: 'View Status',
          textColor: Colors.white,
          onPressed: () => context.push(
            '${AppRoutes.loans}/status/${pendingApplication.id}',
          ),
        ),
      );
    } else {
      context.push('${AppRoutes.loans}/apply');
    }
  }

  Widget _buildGuarantorBanner(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColorConstants.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: ColorConstants.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.warning.outline,
            color: ColorConstants.warning,
            size: AppSizes.iconM,
          ),
          const SizedBox(width: AppSizes.spacingS),
          Expanded(
            child: Text(
              'You have $count pending guarantee request(s) awaiting your decision.',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => context.push('${AppRoutes.loans}/guarantors'),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveLoanBanner(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.wallet.outline,
                color: colorScheme.primary,
                size: AppSizes.iconM,
              ),
              const SizedBox(width: AppSizes.spacingS),
              Text(
                'No Active Loan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            'Active members with 2+ months savings can apply for up to 20,000 ETB with a 10% one-time service charge.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('${AppRoutes.loans}/apply'),
              icon: Icon(AppIcons.add.outline, size: AppSizes.iconS),
              label: const Text('Apply for Member Loan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApplicationBanner(
    BuildContext context,
    LoanApplicationEntity application,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusText = application.status.name
        .replaceAll('_', ' ')
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: ColorConstants.warning.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstants.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.clock.outline,
                  color: ColorConstants.warning,
                  size: AppSizes.iconS,
                ),
              ),
              const SizedBox(width: AppSizes.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application In Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ref: #${application.applicationNumber} • $statusText',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ColorConstants.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            'Your loan application is currently under dual-control review. New loan applications are locked until this evaluation is finalized.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.push('${AppRoutes.loans}/status/${application.id}'),
              icon: Icon(AppIcons.forward.outline, size: AppSizes.iconS),
              label: const Text('View Application Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    String? subtitle,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: AppSizes.iconS),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingM),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyApplicationsState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingL),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(AppIcons.document.outline, size: 36, color: theme.hintColor),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            'No loan applications yet',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationTile(
    BuildContext context,
    LoanApplicationEntity app,
    NumberFormat currencyFormatter,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListTile(
        onTap: () => context.push('${AppRoutes.loans}/application/${app.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              app.applicationNumber.isNotEmpty
                  ? app.applicationNumber
                  : 'Loan Application',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            LoanStatusChip.fromApplicationStatus(app.status, app.approvalCount),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Requested: ${currencyFormatter.format(app.requestedAmount)}',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (app.submittedAt != null)
                Text(
                  DateFormat('dd MMM yyyy').format(app.submittedAt!),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        trailing: Icon(AppIcons.forward.outline, size: AppSizes.iconXs),
      ),
    );
  }
}
