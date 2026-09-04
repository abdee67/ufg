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
import 'package:ufg/features/loans/presentation/bloc/loan_bloc.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_event.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_state.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_financial_breakdown.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_status_chip.dart';
import 'package:ufg/features/loans/presentation/widgets/repayment_schedule_card.dart';

class LoanDetailPage extends StatefulWidget {
  final String loanId;

  const LoanDetailPage({
    super.key,
    required this.loanId,
  });

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  @override
  void initState() {
    super.initState();
    _loadLoan();
  }

  void _loadLoan() {
    context.read<LoanBloc>().add(LoadLoanDetailsRequested(widget.loanId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormatter = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Loan Details',
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
            _loadLoan();
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
              title: 'Unable to load loan',
              message: state.message,
              onRetry: _loadLoan,
            );
          }

          if (state is LoanDetailsLoaded) {
            final loan = state.loan;
            final installments = state.installments;

            return RefreshIndicator(
              onRefresh: () async => _loadLoan(),
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  // Balance & Status Card
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
                              loan.loanNumber,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            LoanStatusChip.fromLoanStatus(loan.status),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spacingM),
                        Text(
                          'Outstanding Balance',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormatter.format(loan.outstandingBase),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingM),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: loan.repaymentProgress,
                            minHeight: 6,
                            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              loan.isOverdue || loan.isDefaulted
                                  ? ColorConstants.warning
                                  : ColorConstants.success,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Paid: ${currencyFormatter.format(loan.totalPaid)}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Total: ${currencyFormatter.format(loan.totalRepayment)}',
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacingL),

                  // Actions: Make Payment / Request Extension
                  Row(
                    children: [
                      if (!loan.isPaid) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('${AppRoutes.loans}/repay/${loan.id}'),
                            icon: Icon(AppIcons.card.outline, size: AppSizes.iconS),
                            label: const Text('Make Repayment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacingS),
                      ],
                      if (!loan.isPaid && !loan.isDefaulted)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('${AppRoutes.loans}/extension/${loan.id}'),
                            icon: Icon(AppIcons.clock.outline, size: AppSizes.iconS),
                            label: const Text('Request Extension'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.spacingL),

                  // Repayment Schedule
                  RepaymentScheduleCard(
                    installments: installments,
                    onPayInstallment: (inst) => context.push('${AppRoutes.loans}/repay/${loan.id}'),
                  ),

                  const SizedBox(height: AppSizes.spacingL),

                  // Financial Breakdown
                  LoanFinancialBreakdown(
                    principal: loan.principal,
                    serviceChargeRate: loan.serviceChargeRate,
                    termMonths: loan.termMonths,
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
