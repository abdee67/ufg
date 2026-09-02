import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_event.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_state.dart';

enum SavingsDepositType {
  monthlyRequired,
  anyTimeContribution,
}

class SavingsPaymentPage extends StatefulWidget {
  final SavingsObligationEntity? obligation;

  const SavingsPaymentPage({super.key, this.obligation});

  @override
  State<SavingsPaymentPage> createState() => _SavingsPaymentPageState();
}

class _SavingsPaymentPageState extends State<SavingsPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();

  SavingsDepositType _depositType = SavingsDepositType.monthlyRequired;
  String _selectedPaymentMethod = 'bank_transfer';
  PlatformFile? _pickedFile;
  int _pickedFileSize = 0;

  @override
  void initState() {
    super.initState();
    _applyDepositType(SavingsDepositType.monthlyRequired);
  }

  void _applyDepositType(SavingsDepositType type) {
    setState(() {
      _depositType = type;
      if (type == SavingsDepositType.monthlyRequired) {
        if (widget.obligation != null) {
          _amountController.text = widget.obligation!.totalDue.toStringAsFixed(0);
        } else {
          _amountController.text = '2000';
        }
      } else {
        if (_amountController.text == '2000') {
          _amountController.clear();
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickProofDocument() async {
    try {
      final PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );

      if (file != null) {
        final int sizeInByte = await file.length();
        const int maxAllowedSize = 10 * 1024 * 1024;
        if (sizeInByte > maxAllowedSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Selected proof exceeds the 10MB limit. Please choose a smaller file.',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }

        setState(() {
          _pickedFile = file;
          _pickedFileSize = sizeInByte;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick document: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _determineMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  void _submitPayment() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    final String? obligationId = _depositType == SavingsDepositType.monthlyRequired
        ? widget.obligation?.id
        : null;

    context.read<SavingsBloc>().add(
          SubmitSavingsPaymentRequested(
            amount: amount,
            paymentMethodCode: _selectedPaymentMethod,
            externalReference: _referenceController.text.trim(),
            filePath: _pickedFile?.path,
            fileName: _pickedFile?.name,
            mimeType: _pickedFile != null ? _determineMimeType(_pickedFile!.name) : null,
            fileSizeBytes: _pickedFileSize > 0 ? _pickedFileSize : null,
            obligationId: obligationId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormatter = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    final isMonthlyRequired = _depositType == SavingsDepositType.monthlyRequired;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Deposit Savings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<SavingsBloc, SavingsState>(
        listener: (context, state) {
          if (state is SavingsActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.primary,
              ),
            );
            context.go(AppRoutes.savings);
          } else if (state is SavingsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is SavingsActionInProgress;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Deposit Type',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DepositTypeOptionCard(
                          title: 'Monthly Required',
                          subtitle: '2,000 ETB (Fixed)',
                          icon: Icons.event_repeat_rounded,
                          isSelected: isMonthlyRequired,
                          onTap: () => _applyDepositType(SavingsDepositType.monthlyRequired),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DepositTypeOptionCard(
                          title: 'Any Time Saving',
                          subtitle: 'Flexible / Voluntary',
                          icon: Icons.volunteer_activism_rounded,
                          isSelected: !isMonthlyRequired,
                          onTap: () => _applyDepositType(SavingsDepositType.anyTimeContribution),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (widget.obligation != null && isMonthlyRequired) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.obligation!.isLate
                              ? Colors.red.shade200
                              : colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment for ${widget.obligation!.periodLabel}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.obligation!.isLate)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'LATE',
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Required: ${currencyFormatter.format(widget.obligation!.requiredAmount)}'
                            '${widget.obligation!.hasPenalty ? ' + Penalty: ${currencyFormatter.format(widget.obligation!.latePenaltyAmount)}' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contribution Amount (ETB)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isMonthlyRequired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock_rounded, size: 12, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Fixed Requirement',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    readOnly: isMonthlyRequired,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: isMonthlyRequired ? '2000' : 'Enter voluntary amount (e.g. 5000)',
                      prefixIcon: Icon(
                        isMonthlyRequired ? Icons.lock_outline_rounded : Icons.savings_outlined,
                        color: isMonthlyRequired ? theme.hintColor : colorScheme.primary,
                      ),
                      fillColor: isMonthlyRequired ? theme.dividerColor.withValues(alpha: 0.1) : null,
                      filled: isMonthlyRequired,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a contribution amount';
                      }
                      final num = double.tryParse(val.trim());
                      if (num == null || num <= 0) {
                        return 'Please enter a valid amount greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMonthlyRequired
                        ? 'Fixed minimum monthly saving of 2,000 ETB due by the 12th of each month.'
                        : 'Any time voluntary contribution — enter any custom amount to grow your savings balance.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Payment Method',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPaymentMethod,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'bank_transfer',
                            child: Row(
                              children: [
                                Icon(Icons.account_balance_rounded, size: 20),
                                SizedBox(width: 12),
                                Text('Bank Transfer (CBE / Awash / Dashen)'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'wallet',
                            child: Row(
                              children: [
                                Icon(Icons.account_balance_wallet_rounded, size: 20),
                                SizedBox(width: 12),
                                Text('Mobile Wallet (Telebirr / CBEBirr)'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedPaymentMethod = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Transaction Reference / Receipt ID',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _referenceController,
                    decoration: InputDecoration(
                      hintText: 'e.g. FT260901ABCD / TXN123456',
                      prefixIcon: const Icon(Icons.tag_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide the transaction reference number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Payment Proof / Receipt Screenshot (Optional)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickProofDocument,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _pickedFile != null
                              ? ColorConstants.brandGreen
                              : theme.dividerColor,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _pickedFile != null
                                ? Icons.check_circle_rounded
                                : Icons.upload_file_rounded,
                            color: _pickedFile != null
                                ? ColorConstants.brandGreen
                                : theme.hintColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickedFile != null
                                      ? _pickedFile!.name
                                      : 'Tap to upload screenshot or PDF',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: _pickedFile != null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_pickedFileSize > 0)
                                  Text(
                                    '${(_pickedFileSize / 1024).toStringAsFixed(1)} KB',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_pickedFile != null)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                setState(() {
                                  _pickedFile = null;
                                  _pickedFileSize = 0;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Payment for Verification',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DepositTypeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DepositTypeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2.0 : 1.0,
          ),
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
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : colorScheme.primary,
                    size: 18,
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? colorScheme.primary : theme.hintColor,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
