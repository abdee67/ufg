import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/custom_textField.dart';
import 'package:ufg/core/widgets/loading_indicator.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/loans/domain/entities/guarantor_candidate_entity.dart';
import 'package:ufg/features/loans/domain/entities/loan_product_entity.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_bloc.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_event.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_state.dart';
import 'package:ufg/features/loans/presentation/widgets/loan_financial_breakdown.dart';

/// Public, unauthenticated outsider application.  It deliberately has no
/// status lookup: a reference alone must never reveal financial information.
class OutsiderLoanApplicationPage extends StatefulWidget {
  const OutsiderLoanApplicationPage({super.key});

  @override
  State<OutsiderLoanApplicationPage> createState() =>
      _OutsiderLoanApplicationPageState();
}

class _OutsiderLoanApplicationPageState
    extends State<OutsiderLoanApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _purposeController = TextEditingController();
  final _amountController = TextEditingController();
  final _guarantorSearchController = TextEditingController();

  LoanProductEntity? _product;
  GuarantorCandidateEntity? _guarantor;
  List<GuarantorCandidateEntity> _candidates = [];

  @override
  void initState() {
    super.initState();
    context.read<LoanBloc>().add(LoadActiveOutsiderLoanProductRequested());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _purposeController.dispose();
    _amountController.dispose();
    _guarantorSearchController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate() ||
        _product == null ||
        _guarantor == null) {
      if (_guarantor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select an active member guarantor.')),
        );
      }
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0 || amount > _product!.maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter an amount up to ${_product!.maxAmount.toStringAsFixed(0)} ETB.',
          ),
        ),
      );
      return;
    }
    context.read<LoanBloc>().add(
      SubmitOutsiderLoanApplicationRequested(
        loanProductId: _product!.id,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        requestedAmount: amount,
        purpose: _purposeController.text,
        guarantorMemberId: _guarantor!.memberId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outsider loan application'),
        leading: IconButton(
          icon: Icon(AppIcons.back.outline),
          onPressed: () => context.go(AppRoutes.loginScreen),
        ),
      ),
      body: BlocConsumer<LoanBloc, LoanState>(
        listener: (context, state) {
          if (state is OutsiderLoanProductLoaded) {
            setState(() => _product = state.product);
          } else if (state is LoanGuarantorSearchLoaded) {
            setState(() => _candidates = state.candidates);
          } else if (state is LoanActionSuccess && state.data != null) {
            _showReceipt(state.data!);
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
          if (_product == null && state is LoanLoading) {
            return const Center(child: LoadingIndicator());
          }
          final product = _product;
          final isSubmitting = state is LoanActionInProgress;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apply without a member account',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  Text(
                    'An active Unity Finance member must accept responsibility as your guarantor. Your final maximum is calculated privately from their savings and verified by the server.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  _sectionTitle(theme, '1. Your details'),
                  CustomTextField(
                    controller: _fullNameController,
                    label: 'Full name',
                    icon: AppIcons.user.outline,
                    validator: _required,
                  ),
                  const SizedBox(height: AppSizes.fieldGap),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone number',
                    icon: AppIcons.phone.outline,
                    keyboardType: TextInputType.phone,
                    validator: _phoneValidator,
                  ),
                  const SizedBox(height: AppSizes.fieldGap),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: AppIcons.profile.outline,
                    maxLines: 2,
                    validator: _required,
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  _sectionTitle(theme, '2. Select guarantor'),
                  CustomTextField(
                    controller: _guarantorSearchController,
                    label: 'Search active members',
                    hintText: 'Member number or name',
                    icon: AppIcons.search.outline,
                    onChanged: (query) {
                      _guarantor = null;
                      if (query.trim().length >= 2) {
                        context.read<LoanBloc>().add(
                          SearchLoanGuarantorsRequested(query),
                        );
                      } else {
                        setState(() => _candidates = []);
                      }
                    },
                  ),
                  if (_guarantor != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSizes.spacingS),
                      child: Text(
                        'Guarantor: ${_guarantor!.displayName} (${_guarantor!.memberNumber})',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (_candidates.isNotEmpty) _candidateList(theme),
                  const SizedBox(height: AppSizes.spacingL),
                  _sectionTitle(theme, '3. Loan request'),
                  if (product != null) ...[
                    Text(
                      'Service charge: ${(product.serviceChargeRate * 100).toStringAsFixed(0)}% • ${product.termMonths} months • Cap: ${NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0).format(product.maxAmount)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                  ],
                  CustomTextField(
                    controller: _amountController,
                    label: 'Requested amount (ETB)',
                    icon: AppIcons.wallet.outline,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: _amountValidator,
                  ),
                  if (product != null &&
                      double.tryParse(_amountController.text) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSizes.spacingM),
                      child: LoanFinancialBreakdown(
                        principal: double.parse(_amountController.text),
                        serviceChargeRate: product.serviceChargeRate,
                        termMonths: product.termMonths,
                      ),
                    ),
                  const SizedBox(height: AppSizes.fieldGap),
                  CustomTextField(
                    controller: _purposeController,
                    label: 'Purpose',
                    icon: AppIcons.document.outline,
                    maxLines: 2,
                    validator: _required,
                  ),
                  const SizedBox(height: AppSizes.spacingXl),
                  PrimaryButton(
                    label: 'Submit outsider loan request',
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _candidateList(ThemeData theme) => Container(
    margin: const EdgeInsets.only(top: AppSizes.spacingS),
    decoration: BoxDecoration(
      border: Border.all(color: theme.dividerColor),
      borderRadius: BorderRadius.circular(AppSizes.radiusField),
    ),
    child: Column(
      children: _candidates
          .map(
            (candidate) => ListTile(
              title: Text(candidate.displayName),
              subtitle: Text(candidate.memberNumber),
              onTap: () => setState(() {
                _guarantor = candidate;
                _guarantorSearchController.text = candidate.displayName;
                _candidates = [];
              }),
            ),
          )
          .toList(),
    ),
  );

  Widget _sectionTitle(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.spacingS),
    child: Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;
  String? _phoneValidator(String? value) =>
      value == null || value.trim().length < 7
      ? 'Enter a valid phone number.'
      : null;
  String? _amountValidator(String? value) =>
      double.tryParse(value?.trim() ?? '') == null
      ? 'Enter a valid amount.'
      : null;

  void _showReceipt(Map<String, dynamic> data) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Request submitted'),
        content: Text(
          'Keep this reference for your records: ${data['application_number'] ?? 'Pending reference'}\n\nYour guarantor must accept before the application can proceed.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.loginScreen),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
