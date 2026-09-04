import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/utils/formatters.dart';
import 'package:ufg/core/widgets/primary_button.dart';
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
                behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
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
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.6);
    final errorBg = isDark
        ? ColorConstants.errorSubtleDark
        : ColorConstants.errorSubtle;
    final errorFg = isDark
        ? colorScheme.error.withValues(alpha: 0.9)
        : colorScheme.error;

    final isMonthlyRequired = _depositType == SavingsDepositType.monthlyRequired;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Deposit Savings'),
        leading: IconButton(
          icon: Icon(AppIcons.back.outline, size: AppSizes.iconM),
          tooltip: 'Back',
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
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go(AppRoutes.savings);
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
          final isLoading = state is SavingsActionInProgress;

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
                  Text(
                    'Select Deposit Type',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  Row(
                    children: [
                      Expanded(
                        child: _DepositTypeOptionCard(
                          title: 'Monthly Required',
                          subtitle: '2,000 ETB (Fixed)',
                          icon: AppIcons.calendar.outline,
                          isSelected: isMonthlyRequired,
                          onTap: () =>
                              _applyDepositType(SavingsDepositType.monthlyRequired),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingS),
                      Expanded(
                        child: _DepositTypeOptionCard(
                          title: 'Any Time Saving',
                          subtitle: 'Flexible / Voluntary',
                          icon: AppIcons.savings.outline,
                          isSelected: !isMonthlyRequired,
                          onTap: () => _applyDepositType(
                            SavingsDepositType.anyTimeContribution,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  if (widget.obligation != null && isMonthlyRequired) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSizes.spacingM),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                        border: Border.all(
                          color: widget.obligation!.isLate
                              ? errorFg.withValues(alpha: 0.4)
                              : colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Payment for ${widget.obligation!.periodLabel}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (widget.obligation!.isLate)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.spacingXs,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: errorBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'LATE',
                                    style: TextStyle(
                                      color: errorFg,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Required: ${Formatters.money(widget.obligation!.requiredAmount)}'
                            '${widget.obligation!.hasPenalty ? ' + Penalty: ${Formatters.money(widget.obligation!.latePenaltyAmount)}' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingL),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spacingXs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusChip,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                AppIcons.lock.outline,
                                size: 12,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: AppSizes.spacingXxs),
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
                  const SizedBox(height: AppSizes.spacingXs),
                  TextFormField(
                    controller: _amountController,
                    readOnly: isMonthlyRequired,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: isMonthlyRequired ? '2000' : 'Enter voluntary amount (e.g. 5000)',
                      prefixIcon: Icon(
                        isMonthlyRequired
                            ? AppIcons.lock.outline
                            : AppIcons.savings.outline,
                        color: isMonthlyRequired
                            ? secondaryText
                            : colorScheme.primary,
                      ),
                      fillColor: isMonthlyRequired
                          ? theme.dividerColor.withValues(alpha: 0.1)
                          : colorScheme.surface,
                      filled: true,
                      border: _fieldBorder(),
                      enabledBorder: _fieldBorder(),
                      focusedBorder: _fieldBorder(color: colorScheme.primary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a contribution amount';
                      }
                      final num = double.tryParse(val.trim());
                      if (num == null || num <= 0) {
                        return 'Enter an amount greater than 0 ETB';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingXs),
                  Text(
                    isMonthlyRequired
                        ? 'Fixed minimum monthly saving of 2,000 ETB due by the 12th of each month.'
                        : 'Any time voluntary contribution — enter any custom amount to grow your savings balance.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  Text(
                    'Payment Method',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacingM,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPaymentMethod,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'bank_transfer',
                            child: Row(
                              children: [
                                Icon(AppIcons.bank.outline, size: AppSizes.iconS),
                                const SizedBox(width: AppSizes.spacingS),
                                const Expanded(
                                  child: Text(
                                    'Bank Transfer (CBE / Awash / Dashen)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'wallet',
                            child: Row(
                              children: [
                                Icon(AppIcons.card.outline, size: AppSizes.iconS),
                                const SizedBox(width: AppSizes.spacingS),
                                const Expanded(
                                  child: Text(
                                    'Mobile Wallet (Telebirr / CBEBirr)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                  const SizedBox(height: AppSizes.spacingL),
                  Text(
                    'Transaction Reference / Receipt ID',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXs),
                  TextFormField(
                    controller: _referenceController,
                    decoration: InputDecoration(
                      hintText: 'e.g. FT260901ABCD / TXN123456',
                      prefixIcon: Icon(
                        AppIcons.receiptItem.outline,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: _fieldBorder(),
                      enabledBorder: _fieldBorder(),
                      focusedBorder: _fieldBorder(color: colorScheme.primary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide the transaction reference number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                  Text(
                    'Payment Proof / Receipt Screenshot (Optional)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXs),
                  InkWell(
                    onTap: _pickProofDocument,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.spacingM),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
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
                                ? AppIcons.check.outline
                                : AppIcons.upload.outline,
                            color: _pickedFile != null
                                ? ColorConstants.success
                                : secondaryText,
                          ),
                          const SizedBox(width: AppSizes.spacingS),
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
                                      color: secondaryText,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_pickedFile != null)
                            IconButton(
                              icon: Icon(
                                AppIcons.close.outline,
                                size: AppSizes.iconS - 2,
                              ),
                              tooltip: 'Remove file',
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
                  const SizedBox(height: AppSizes.spacingXxl),
                  PrimaryButton(
                    label: 'Submit Payment for Verification',
                    isLoading: isLoading,
                    onPressed: _submitPayment,
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
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.spacingS + 2),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
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
                  padding: const EdgeInsets.all(AppSizes.spacingXs),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? ColorConstants.onBrand
                        : colorScheme.primary,
                    size: AppSizes.iconS - 2,
                  ),
                ),
                Icon(
                  isSelected
                      ? AppIcons.check.outline
                      : AppIcons.info.outline,
                  color: isSelected ? colorScheme.primary : theme.hintColor,
                  size: AppSizes.iconS - 2,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingS),
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
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}