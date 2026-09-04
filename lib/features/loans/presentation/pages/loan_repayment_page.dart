import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/custom_app_bar.dart';
import 'package:ufg/core/widgets/custom_textField.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_bloc.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_event.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_state.dart';

class LoanRepaymentPage extends StatefulWidget {
  final String loanId;

  const LoanRepaymentPage({super.key, required this.loanId});

  @override
  State<LoanRepaymentPage> createState() => _LoanRepaymentPageState();
}

class _LoanRepaymentPageState extends State<LoanRepaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '2200');
  final _referenceController = TextEditingController();

  String _paymentMethod = 'bank_transfer';
  PlatformFile? _pickedFile;
  int _pickedFileSize = 0;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final PlatformFile? file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (file != null) {
      final int sizeInByte = await file.length();
      if (sizeInByte > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selected document exceeds the 5MB limit. Please choose a smaller file.',
            ),
          ),
        );
        return;
      }
      setState(() {
        _pickedFile = file;
        _pickedFileSize = sizeInByte;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid repayment amount.')),
      );
      return;
    }

    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a payment receipt / proof.'),
        ),
      );
      return;
    }

    final mimeType = lookupMimeType(_pickedFile!.path ?? '') ?? 'image/jpeg';
    final int fileSize = _pickedFileSize;

    context.read<LoanBloc>().add(
      SubmitLoanRepaymentRequested(
        loanId: widget.loanId,
        amount: amount,
        paymentMethodCode: _paymentMethod,
        externalReference: _referenceController.text.trim(),
        filePath: _pickedFile!.path,
        fileName: _pickedFile!.name,
        mimeType: mimeType,
        fileSizeBytes: fileSize,
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
        title: 'Loan Repayment',
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
          }
        },
        builder: (context, state) {
          final isSubmitting = state is LoanActionInProgress;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bank instructions card
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
                          children: [
                            Icon(
                              AppIcons.card.outline,
                              color: colorScheme.primary,
                              size: AppSizes.iconS,
                            ),
                            const SizedBox(width: AppSizes.spacingXs),
                            Text(
                              'SACCO Repayment Account',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spacingM),
                        _bankRow(
                          'Bank Name:',
                          'Commercial Bank of Ethiopia (CBE)',
                          theme,
                        ),
                        _bankRow(
                          'Account Name:',
                          'Unity Finance Group SACCO',
                          theme,
                        ),
                        _bankRow(
                          'Account Number:',
                          '1000234567890',
                          theme,
                          isBold: true,
                        ),
                        _bankRow(
                          'Telebirr Merchant:',
                          '987654 (Unity Finance)',
                          theme,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacingL),

                  Text(
                    'Repayment Amount',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  CustomTextField(
                    controller: _amountController,
                    label: 'Amount (ETB)',
                    icon: AppIcons.wallet.outline,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty)
                        return 'Enter amount.';
                      final num = double.tryParse(val.replaceAll(',', ''));
                      if (num == null || num <= 0) return 'Invalid amount.';
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingL),

                  Text(
                    'Payment Method',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'bank_transfer',
                        label: Text('Bank Transfer'),
                        icon: Icon(Icons.account_balance_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: 'wallet',
                        label: Text('Telebirr / Wallet'),
                        icon: Icon(Icons.phone_android_rounded, size: 16),
                      ),
                    ],
                    selected: {_paymentMethod},
                    onSelectionChanged: (val) {
                      setState(() => _paymentMethod = val.first);
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingL),

                  Text(
                    'Bank Transaction Reference',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  CustomTextField(
                    controller: _referenceController,
                    label: 'Transaction Reference / FT Number',
                    hintText: 'e.g. FT260902ABCD',
                    icon: AppIcons.document.outline,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide bank transaction reference.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingL),

                  Text(
                    'Payment Receipt Proof',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),

                  InkWell(
                    onTap: _pickProof,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.spacingL),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusCard,
                        ),
                        border: Border.all(
                          color: _pickedFile != null
                              ? ColorConstants.success
                              : theme.dividerColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _pickedFile != null
                                ? AppIcons.check.outline
                                : AppIcons.upload.outline,
                            color: _pickedFile != null
                                ? ColorConstants.success
                                : colorScheme.primary,
                            size: AppSizes.iconM,
                          ),
                          const SizedBox(width: AppSizes.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickedFile != null
                                      ? _pickedFile!.name
                                      : 'Upload Screenshot / Receipt PDF',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _pickedFile != null
                                      ? '${(_pickedFileSize / 1024).toStringAsFixed(1)} KB'
                                      : 'Supports JPG, PNG, PDF (Max 5MB)',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _pickProof,
                            child: Text(
                              _pickedFile != null ? 'Change' : 'Browse',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacingXl),

                  PrimaryButton(
                    label: 'Submit Repayment for Verification',
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

  Widget _bankRow(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
