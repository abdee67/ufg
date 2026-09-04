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
  final _guarantorController = TextEditingController();
  final _amountController = TextEditingController(text: '6000');

  double _requestedAmount = 6000.0;
  LoanProductEntity? _selectedProduct;
  List<LoanProductEntity> _products = [];

  @override
  void initState() {
    super.initState();
    context.read<LoanBloc>().add(LoadLoanProductsRequested());
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _guarantorController.dispose();
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
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a loan product.')),
      );
      return;
    }

    if (_selectedProduct!.isOutsiderLoan && _guarantorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outsider loan requires a member guarantor ID.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    context.read<LoanBloc>().add(
          SubmitLoanApplicationRequested(
            loanProductId: _selectedProduct!.id,
            requestedAmount: _requestedAmount,
            purpose: _purposeController.text.trim(),
            guarantorMemberId: _selectedProduct!.isOutsiderLoan
                ? _guarantorController.text.trim()
                : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormatter = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

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
              _products = state.products;
              if (_products.isNotEmpty && _selectedProduct == null) {
                _selectedProduct = _products.firstWhere(
                  (p) => p.isMemberLoan,
                  orElse: () => _products.first,
                );
              }
            });
          }
        },
        builder: (context, state) {
          if (state is LoanLoading && _products.isEmpty) {
            return const Center(child: LoadingIndicator());
          }

          final isSubmitting = state is LoanActionInProgress;
          final maxLimit = _selectedProduct?.maxAmount ?? 20000.0;
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
                    ..._products.map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.spacingS),
                        child: LoanProductCard(
                          product: product,
                          isSelected: _selectedProduct?.id == product.id,
                          onTap: () {
                            setState(() {
                              _selectedProduct = product;
                              if (_requestedAmount > product.maxAmount) {
                                _requestedAmount = product.maxAmount;
                                _amountController.text = product.maxAmount.toStringAsFixed(0);
                              }
                            });
                          },
                        ),
                      ),
                    ),

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
                          value: _requestedAmount.clamp(1000.0, maxLimit),
                          min: 1000.0,
                          max: maxLimit,
                          divisions: ((maxLimit - 1000.0) / 500).round(),
                          label: currencyFormatter.format(_requestedAmount),
                          onChanged: _onAmountChanged,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Min: 1,000 ETB', style: theme.textTheme.bodySmall),
                            Text('Max: ${currencyFormatter.format(maxLimit)}', style: theme.textTheme.bodySmall),
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

                  // If outsider loan, guarantor ID input
                  if (_selectedProduct != null && _selectedProduct!.isOutsiderLoan) ...[
                    Text(
                      '3. Guarantor (Active Member)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                    CustomTextField(
                      controller: _guarantorController,
                      label: 'Guarantor Member ID (UUID)',
                      hintText: 'Enter active member ID',
                      icon: AppIcons.shield.outline,
                      validator: (val) {
                        if (_selectedProduct!.isOutsiderLoan && (val == null || val.trim().isEmpty)) {
                          return 'Guarantor member ID is required for outsider loans.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.spacingL),
                  ],

                  Text(
                    _selectedProduct != null && _selectedProduct!.isOutsiderLoan
                        ? '4. Loan Purpose'
                        : '3. Loan Purpose',
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
                    onPressed: isSubmitting ? null : _submit,
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
}
