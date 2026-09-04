import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/utils/formatters.dart';
import 'package:ufg/core/widgets/app_card.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_event.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_state.dart';

class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({super.key});

  @override
  State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  double _availableToWithdraw = 0.0;
  double _totalSavings = 0.0;
  double _securedSavings = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<SavingsBloc>().add(LoadSavingsSummaryRequested());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submitWithdrawal() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    if (amount > _availableToWithdraw) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Requested amount exceeds available balance of ${Formatters.money(_availableToWithdraw)}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<SavingsBloc>().add(
          RequestSavingsWithdrawalRequested(
            amount: amount,
            reason: _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.6);
    final warningBg = isDark
        ? ColorConstants.warningSubtleDark
        : ColorConstants.warningSubtle;
    final warningFg = isDark
        ? ColorConstants.warningDark
        : ColorConstants.warning;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Request Withdrawal'),
        leading: IconButton(
          icon: Icon(AppIcons.back.outline, size: AppSizes.iconM),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(AppIcons.history.outline, size: AppSizes.iconM),
            tooltip: 'My Withdrawal Requests',
            onPressed: () => context.push(AppRoutes.savingsWithdrawals),
          ),
        ],
      ),
      body: BlocConsumer<SavingsBloc, SavingsState>(
        listener: (context, state) {
          if (state is SavingsSummaryLoaded) {
            setState(() {
              _totalSavings = state.summary.totalSavings;
              _availableToWithdraw = state.summary.availableToWithdraw;
              _securedSavings = state.summary.securedSavings;
            });
          } else if (state is SavingsActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go(AppRoutes.savingsWithdrawals);
          } else if (state is SavingsFailure) {
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
          final isLoading =
              state is SavingsLoading || state is SavingsActionInProgress;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingL,
              vertical: AppSizes.spacingM,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    padding: AppSizes.spacingM + 2,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available to Withdraw',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: secondaryText,
                              ),
                            ),
                            Text(
                              Formatters.money(_availableToWithdraw),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Savings',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secondaryText,
                              ),
                            ),
                            Text(
                              Formatters.money(_totalSavings),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spacingXxs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Secured for Loans',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secondaryText,
                              ),
                            ),
                            Text(
                              Formatters.money(_securedSavings),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _securedSavings > 0 ? warningFg : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_securedSavings > 0) ...[
                    const SizedBox(height: AppSizes.spacingS),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.spacingS),
                      decoration: BoxDecoration(
                        color: warningBg,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusChip + 6,
                        ),
                        border: Border.all(
                          color: warningFg.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.lock.outline,
                            color: warningFg,
                            size: AppSizes.iconS - 2,
                          ),
                          const SizedBox(width: AppSizes.spacingXs),
                          Expanded(
                            child: Text(
                              '${Formatters.money(_securedSavings)} is locked as loan security and cannot be withdrawn.',
                              style: TextStyle(
                                color: warningFg,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.spacingXl),
                  Text(
                    'Withdrawal Amount (ETB)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXs),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. 5000',
                      prefixIcon: Icon(
                        AppIcons.payments.outline,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: _fieldBorder(),
                      enabledBorder: _fieldBorder(),
                      focusedBorder: _fieldBorder(color: colorScheme.primary),
                      suffixIcon: TextButton(
                        onPressed: () {
                          _amountController.text =
                              _availableToWithdraw.toStringAsFixed(0);
                        },
                        child: const Text('MAX'),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a withdrawal amount';
                      }
                      final num = double.tryParse(val.trim());
                      if (num == null || num <= 0) {
                        return 'Enter an amount greater than 0 ETB';
                      }
                      if (num > _availableToWithdraw) {
                        return 'Amount cannot exceed ${Formatters.money(_availableToWithdraw)}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  Text(
                    'Reason for Withdrawal (Optional)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXs),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g. Emergency medical expenses',
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: _fieldBorder(),
                      enabledBorder: _fieldBorder(),
                      focusedBorder: _fieldBorder(color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXl),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.spacingS + 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          AppIcons.info.outline,
                          color: colorScheme.primary,
                          size: AppSizes.iconS - 2,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Withdrawal requests are reviewed by authorized group management to protect group liquidity. You will receive live status updates.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXxl),
                  PrimaryButton(
                    label: 'Submit Withdrawal Request',
                    isLoading: isLoading,
                    onPressed: _submitWithdrawal,
                  ),
                  const SizedBox(height: AppSizes.spacingHero),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  OutlineInputBorder _fieldBorder({Color color = Colors.transparent}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusField),
      borderSide: BorderSide(color: color, width: 1.4),
    );
  }
}