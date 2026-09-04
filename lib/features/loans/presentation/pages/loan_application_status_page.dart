import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/custom_app_bar.dart';
import 'package:ufg/core/widgets/error_state.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/features/loans/domain/entities/loan_application_entity.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_bloc.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_event.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_state.dart';
import 'package:ufg/features/loans/presentation/widgets/eligibility_checklist.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_financial_breakdown.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_status_chip.dart';

class LoanApplicationStatusPage extends StatefulWidget {
  final String applicationId;

  const LoanApplicationStatusPage({super.key, required this.applicationId});

  @override
  State<LoanApplicationStatusPage> createState() =>
      _LoanApplicationStatusPageState();
}

class _LoanApplicationStatusPageState extends State<LoanApplicationStatusPage> {
  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() {
    context.read<LoanBloc>().add(
      LoadLoanApplicationDetailRequested(widget.applicationId),
    );
  }

  void _cancelApplication() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Application'),
        content: const Text(
          'Are you sure you want to cancel this loan application? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Application'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<LoanBloc>().add(
                CancelLoanApplicationRequested(widget.applicationId),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormatter = NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Application Status',
        fallbackRoute: AppRoutes.loans,
      ),
      body: BlocConsumer<LoanBloc, LoanState>(
        listener: (context, state) {
          if (state is LoanActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ColorConstants.success,
              ),
            );
            _loadDetails();
          } else if (state is LoanFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ColorConstants.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LoanLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (state is LoanFailure) {
            return ErrorState(
              title: 'Unable to load application',
              message: state.message,
              onRetry: _loadDetails,
            );
          }

          if (state is LoanApplicationDetailLoaded) {
            final app = state.application;
            final eligibility = state.eligibility;
            final guarantor = state.guarantor;

            final isReviewable =
                app.status == LoanApplicationStatus.submitted ||
                app.status == LoanApplicationStatus.underReview ||
                app.status == LoanApplicationStatus.eligible;

            return RefreshIndicator(
              onRefresh: () async => _loadDetails(),
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  // Header Summary Card
                  Container(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              app.applicationNumber.isNotEmpty
                                  ? app.applicationNumber
                                  : 'Loan Application',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            LoanStatusChip.fromApplicationStatus(
                              app.status,
                              app.approvalCount,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spacingM),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Requested Amount:',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              currencyFormatter.format(app.requestedAmount),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (app.submittedAt != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Submitted On:',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                ).format(app.submittedAt!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (app.purpose != null && app.purpose!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Purpose: ${app.purpose}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacingL),

                  // Two-Person Approval Process Timeline
                  _buildApprovalTimeline(context, app),

                  const SizedBox(height: AppSizes.spacingL),

                  // Eligibility Checklist
                  if (eligibility != null) ...[
                    EligibilityChecklistWidget(eligibility: eligibility),
                    const SizedBox(height: AppSizes.spacingL),
                  ],

                  // Financial Breakdown
                  if (app.product != null) ...[
                    LoanFinancialBreakdown(
                      principal: app.requestedAmount,
                      serviceChargeRate: app.product!.serviceChargeRate,
                      termMonths: app.product!.termMonths,
                    ),
                    const SizedBox(height: AppSizes.spacingL),
                  ],

                  // Cancel Button
                  if (isReviewable) ...[
                    Center(
                      child: TextButton.icon(
                        onPressed: _cancelApplication,
                        icon: Icon(
                          AppIcons.close.outline,
                          size: AppSizes.iconS,
                          color: ColorConstants.error,
                        ),
                        label: Text(
                          'Cancel Application',
                          style: TextStyle(
                            color: ColorConstants.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildApprovalTimeline(
    BuildContext context,
    LoanApplicationEntity app,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isApproved = app.status == LoanApplicationStatus.approved;
    final hasOneApproval = app.approvalCount >= 1;
    final hasTwoApprovals = app.approvalCount >= 2;

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
                AppIcons.shield.outline,
                color: colorScheme.primary,
                size: AppSizes.iconS,
              ),
              const SizedBox(width: AppSizes.spacingXs),
              Text(
                'Approval Progress (2 Approvers Required)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          _step(
            '1. Application & Eligibility',
            'Application submitted & checked by automated eligibility engine.',
            isDone: true,
            isActive: false,
            colorScheme: colorScheme,
            theme: theme,
          ),
          _step(
            '2. First Authorized Approval',
            hasOneApproval
                ? 'Approved by 1st committee officer.'
                : 'Awaiting 1st review by authorized credit officer.',
            isDone: hasOneApproval,
            isActive: !hasOneApproval && isReviewable(app),
            colorScheme: colorScheme,
            theme: theme,
          ),
          _step(
            '3. Second Authorized Approval',
            hasTwoApprovals
                ? 'Approved by 2nd committee officer.'
                : 'Awaiting 2nd independent reviewer approval.',
            isDone: hasTwoApprovals,
            isActive: hasOneApproval && !hasTwoApprovals,
            colorScheme: colorScheme,
            theme: theme,
          ),
          _step(
            '4. Disbursement',
            isApproved
                ? 'Approved for disbursement upon 30% group liquidity validation.'
                : 'Disbursement occurs after 2 approvals & liquidity check.',
            isDone: isApproved,
            isActive: hasTwoApprovals && !isApproved,
            colorScheme: colorScheme,
            theme: theme,
            isLast: true,
          ),
        ],
      ),
    );
  }

  bool isReviewable(LoanApplicationEntity app) {
    return app.status == LoanApplicationStatus.submitted ||
        app.status == LoanApplicationStatus.underReview ||
        app.status == LoanApplicationStatus.eligible;
  }

  Widget _step(
    String title,
    String subtitle, {
    required bool isDone,
    required bool isActive,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool isLast = false,
  }) {
    Color iconBg = isDone
        ? ColorConstants.success
        : (isActive ? colorScheme.primary : Colors.grey.shade400);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone
                      ? Icons.check
                      : (isActive ? Icons.sync : Icons.circle_outlined),
                  size: 14,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone
                        ? ColorConstants.success
                        : Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive ? colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
