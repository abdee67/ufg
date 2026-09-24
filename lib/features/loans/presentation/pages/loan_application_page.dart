import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/custom_app_bar.dart';
import 'package:ufg/core/widgets/custom_textField.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';
import 'package:ufg/features/loans/domain/entities/guarantor_candidate_entity.dart';
import 'package:ufg/features/loans/domain/entities/member_loan_limit_entity.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_bloc.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_event.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_state.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_financial_breakdown.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_product_card.dart';

class LoanApplicationPage extends StatefulWidget {
  const LoanApplicationPage({super.key});

  @override
  State<LoanApplicationPage> createState() => _LoanApplicationPageState();
}

class _LoanApplicationPageState extends State<LoanApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _guarantorSearchController = TextEditingController();
  final _amountController = TextEditingController(text: '6000');

  double _requestedAmount = 6000.0;
  LoanProductEntity? _selectedProduct;
  List<LoanProductEntity> _products = [];
  MemberLoanLimitEntity? _memberLoanLimit;
  List<GuarantorCandidateEntity> _guarantorCandidates = [];
  GuarantorCandidateEntity? _selectedGuarantor;

  @override
  void initState() {
    super.initState();
    context.read<LoanBloc>().add(LoadLoanProductsRequested());
    context.read<LoanBloc>().add(LoadMemberLoanLimitRequested());
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _guarantorSearchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(double val) {
    setState(() {
      _requestedAmount = val;
      _amountController.text = val.toStringAsFixed(0);
    });
  }

  void _submit() {
    if (_memberLoanLimit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking your loan eligibility. Please try again shortly.'),
        ),
      );
      return;
    }

    if (_memberLoanLimit!.hasActiveLoan) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'You have an active loan. You must fully repay your current loan before applying for a new one.',
          ),
          backgroundColor: ColorConstants.error,
          action: _memberLoanLimit!.activeLoanId != null
              ? SnackBarAction(
                  label: 'Repay',
                  textColor: Colors.white,
                  onPressed: () => context.push(
                    '${AppRoutes.loans}/repay/${_memberLoanLimit!.activeLoanId}',
                  ),
                )
              : null,
        ),
      );
      return;
    }

    if (_memberLoanLimit!.hasPendingApplication) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'You already have a loan application in progress. You cannot apply again until it is completed or cancelled.',
          ),
          backgroundColor: ColorConstants.error,
          action: _memberLoanLimit!.pendingApplicationId != null
              ? SnackBarAction(
                  label: 'View Status',
                  textColor: Colors.white,
                  onPressed: () => context.push(
                    '${AppRoutes.loans}/status/${_memberLoanLimit!.pendingApplicationId}',
                  ),
                )
              : null,
        ),
      );
      return;
    }

    if (!_memberLoanLimit!.meetsMinimumSavingHistory) {
      final required = _memberLoanLimit!.requiredSavingMonths;
      final paid = _memberLoanLimit!.paidSavingMonths;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You need $required paid savings months before applying. You currently have $paid.',
          ),
          backgroundColor: ColorConstants.error,
        ),
      );
      return;
    }

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a loan product.')),
      );
      return;
    }

    if (_selectedGuarantor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an active member guarantor.')),
      );
      return;
    }

    if (_memberLoanLimit != null &&
        _requestedAmount > _memberLoanLimit!.maximumLoanAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Requested amount exceeds your current server-calculated limit.',
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    context.read<LoanBloc>().add(
      SubmitLoanApplicationRequested(
        loanProductId: _selectedProduct!.id,
        requestedAmount: _requestedAmount,
        purpose: _purposeController.text.trim(),
        guarantorMemberId: _selectedGuarantor!.memberId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormatter = NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Apply for Loan',
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
            context.go(AppRoutes.loans);
          } else if (state is LoanFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: ColorConstants.error,
              ),
            );
          } else if (state is LoanProductsLoaded) {
            setState(() {
              _products = List<LoanProductEntity>.from(state.products);
              if (_products.isNotEmpty && _selectedProduct == null) {
                _selectedProduct = _products.firstWhere(
                  (p) => p.isMemberLoan,
                  orElse: () => _products.first,
                );
              }
            });
          } else if (state is MemberLoanLimitLoaded) {
            setState(() {
              _memberLoanLimit = state.limit;
              if (_requestedAmount > state.limit.maximumLoanAmount) {
                _requestedAmount = state.limit.maximumLoanAmount;
                _amountController.text = _requestedAmount.toStringAsFixed(0);
              }
            });
          } else if (state is LoanGuarantorSearchLoaded) {
            setState(() => _guarantorCandidates = state.candidates);
          }
        },
        builder: (context, state) {
          if (state is LoanLoading && _products.isEmpty) {
            return const Center(child: LoadingIndicator());
          }

          if (_memberLoanLimit?.hasActiveLoan == true) {
            return _buildActiveLoanBlockedView(context, _memberLoanLimit!);
          }

          if (_memberLoanLimit?.hasPendingApplication == true) {
            return _buildPendingApplicationBlockedView(context, _memberLoanLimit!);
          }

          final isSubmitting = state is LoanActionInProgress;
          final savingHistoryReady =
              _memberLoanLimit?.meetsMinimumSavingHistory ?? false;
          final productCap = _selectedProduct?.maxAmount ?? 20000.0;
          final maxLimit = _memberLoanLimit == null
              ? productCap
              : _memberLoanLimit!.maximumLoanAmount.clamp(0.0, productCap);
          final sliderMax = maxLimit < 1000 ? 1000.0 : maxLimit;
          final serviceRate = _selectedProduct?.serviceChargeRate ?? 0.10;
          final termMonths = _selectedProduct?.termMonths ?? 3;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Select Loan Product',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  if (_products.isEmpty)
                    const Center(child: LoadingIndicator())
                  else
                    ..._products
                        .where((product) => product.isMemberLoan)
                        .map(
                          (product) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSizes.spacingS,
                            ),
                            child: LoanProductCard(
                              product: product,
                              isSelected: _selectedProduct?.id == product.id,
                              onTap: () {
                                setState(() {
                                  _selectedProduct = product;
                                  if (_requestedAmount > product.maxAmount) {
                                    _requestedAmount = product.maxAmount;
                                    _amountController.text = product.maxAmount
                                        .toStringAsFixed(0);
                                  }
                                });
                              },
                            ),
                          ),
                        ),

                  const SizedBox(height: AppSizes.spacingL),

                  if (_memberLoanLimit != null)
                    _MemberLoanLimitCard(limit: _memberLoanLimit!),
                  if (_memberLoanLimit != null)
                    const SizedBox(height: AppSizes.spacingL),

                  Text(
                    '2. Requested Amount',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),

                  Container(
                    padding: const EdgeInsets.all(AppSizes.spacingL),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          currencyFormatter.format(_requestedAmount),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingS),
                        Slider(
                          value: _requestedAmount.clamp(1000.0, sliderMax),
                          min: 1000.0,
                          max: sliderMax,
                          divisions: null,
                          label: currencyFormatter.format(_requestedAmount),
                          onChanged: _onAmountChanged,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Min: 1,000 ETB',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Max: ${currencyFormatter.format(maxLimit)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacingL),

                  // Real-time calculation breakdown
                  LoanFinancialBreakdown(
                    principal: _requestedAmount,
                    serviceChargeRate: serviceRate,
                    termMonths: termMonths,
                  ),

                  const SizedBox(height: AppSizes.spacingL),

                  Text(
                    '3. Choose Guarantor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  CustomTextField(
                    controller: _guarantorSearchController,
                    label: 'Search active members',
                    hintText: 'Member number or name',
                    icon: AppIcons.search.outline,
                    onChanged: (query) {
                      _selectedGuarantor = null;
                      if (query.trim().length >= 2) {
                        context.read<LoanBloc>().add(
                          SearchLoanGuarantorsRequested(query),
                        );
                      } else {
                        setState(() => _guarantorCandidates = []);
                      }
                    },
                    validator: (_) => _selectedGuarantor == null
                        ? 'Select a guarantor from the search results.'
                        : null,
                  ),
                  if (_selectedGuarantor != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSizes.spacingS),
                      child: Text(
                        'Selected: ${_selectedGuarantor!.displayName} (${_selectedGuarantor!.memberNumber})',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (_guarantorCandidates.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: AppSizes.spacingS),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusField,
                        ),
                      ),
                      child: Column(
                        children: _guarantorCandidates
                            .map(
                              (candidate) => ListTile(
                                title: Text(candidate.displayName),
                                subtitle: Text(candidate.memberNumber),
                                onTap: () => setState(() {
                                  _selectedGuarantor = candidate;
                                  _guarantorSearchController.text =
                                      candidate.displayName;
                                  _guarantorCandidates = [];
                                }),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: AppSizes.spacingL),

                  Text(
                    '4. Loan Purpose',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  CustomTextField(
                    controller: _purposeController,
                    label: 'Purpose of Loan',
                    hintText: 'e.g. Business inventory, medical, education',
                    icon: AppIcons.document.outline,
                    maxLines: 2,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please state the loan purpose.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingXl),

                  PrimaryButton(
                    label: 'Submit Loan Application',
                    isLoading: isSubmitting,
                    onPressed: isSubmitting || !savingHistoryReady
                        ? null
                        : _submit,
                  ),
                  const SizedBox(height: AppSizes.spacingXl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveLoanBlockedView(
    BuildContext context,
    MemberLoanLimitEntity limit,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spacingL),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            border: Border.all(
              color: ColorConstants.warning.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorConstants.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.lock.outline,
                  color: ColorConstants.warning,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),
              Text(
                'Active Loan In Progress',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingS),
              Text(
                'You already have an outstanding active loan. According to SACCO lending policy, members must complete full repayment of their existing loan before applying for a new one.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingL),
              if (limit.activeLoanId != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(
                      '${AppRoutes.loans}/repay/${limit.activeLoanId}',
                    ),
                    icon: Icon(AppIcons.moneySend.outline, size: AppSizes.iconS),
                    label: const Text('Make a Loan Repayment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingS),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Back to Loans Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingApplicationBlockedView(
    BuildContext context,
    MemberLoanLimitEntity limit,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spacingL),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            border: Border.all(
              color: ColorConstants.warning.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorConstants.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.clock.outline,
                  color: ColorConstants.warning,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),
              Text(
                'Application Under Review',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingS),
              Text(
                'You already have a loan application currently under review. Multiple simultaneous applications are not allowed. Please await the decision on your pending request.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingL),
              if (limit.pendingApplicationId != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(
                      '${AppRoutes.loans}/status/${limit.pendingApplicationId}',
                    ),
                    icon: Icon(AppIcons.forward.outline, size: AppSizes.iconS),
                    label: const Text('Track Application Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingS),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Back to Loans Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberLoanLimitCard extends StatelessWidget {
  final MemberLoanLimitEntity limit;

  const _MemberLoanLimitCard({required this.limit});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your current member loan limit',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSizes.spacingXs),
          Text(
            money.format(limit.maximumLoanAmount),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXs),
          Text(
            'Calculated from savings of ${money.format(limit.totalSavings)}. The server verifies this again when you submit.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            limit.meetsMinimumSavingHistory
                ? 'Savings history complete: ${limit.paidSavingMonths}/${limit.requiredSavingMonths} paid months.'
                : 'Loan applications require ${limit.requiredSavingMonths} paid savings months. You currently have ${limit.paidSavingMonths}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: limit.meetsMinimumSavingHistory
                  ? ColorConstants.success
                  : ColorConstants.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
