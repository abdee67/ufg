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
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_bloc.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_event.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_state.dart';

class LoanExtensionPage extends StatefulWidget {
  final String loanId;

  const LoanExtensionPage({
    super.key,
    required this.loanId,
  });

  @override
  State<LoanExtensionPage> createState() => _LoanExtensionPageState();
}

class _LoanExtensionPageState extends State<LoanExtensionPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 180)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<LoanBloc>().add(
          RequestLoanExtensionRequested(
            loanId: widget.loanId,
            reason: _reasonController.text.trim(),
            requestedNewDueDate: _selectedDate,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Request Loan Extension',
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
                  Container(
                    padding: const EdgeInsets.all(AppSizes.spacingL),
                    decoration: BoxDecoration(
                      color: ColorConstants.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                      border: Border.all(color: ColorConstants.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(AppIcons.info.outline, color: ColorConstants.warning, size: AppSizes.iconS),
                        const SizedBox(width: AppSizes.spacingS),
                        Expanded(
                          child: Text(
                            'Loan extensions must be requested before reaching serious default (60 days overdue). An extension request is subject to authorized committee approval.',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacingL),

                  Text(
                    'Reason for Extension',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  CustomTextField(
                    controller: _reasonController,
                    label: 'Detailed Reason',
                    hintText: 'Please describe why you require a repayment extension (at least 10 characters)...',
                    icon: AppIcons.document.outline,
                    maxLines: 4,
                    validator: (val) {
                      if (val == null || val.trim().length < 10) {
                        return 'Reason must be at least 10 characters.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSizes.spacingL),

                  Text(
                    'Proposed New Due Date (Optional)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSizes.spacingS),

                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.spacingL),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(AppIcons.calendar.outline, color: colorScheme.primary, size: AppSizes.iconS),
                              const SizedBox(width: AppSizes.spacingS),
                              Text(
                                _selectedDate != null
                                    ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                                    : 'Select proposed due date',
                                style: TextStyle(
                                  fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.normal,
                                  color: _selectedDate != null ? null : theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                          Icon(AppIcons.forward.outline, size: AppSizes.iconXs),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.spacingXl),

                  PrimaryButton(
                    label: 'Submit Extension Request',
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
}
