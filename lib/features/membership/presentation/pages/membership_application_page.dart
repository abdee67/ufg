import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/app_card.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_bloc.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_event.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_state.dart';

class MembershipApplicationPage extends StatefulWidget {
  const MembershipApplicationPage({super.key});

  @override
  State<MembershipApplicationPage> createState() =>
      _MembershipApplicationPageState();
}

class _MembershipApplicationPageState extends State<MembershipApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  bool _agreeToRules = false;

  PlatformFile? _pickedFile;
  int _pickedFileSize = 0;

  @override
  void initState() {
    super.initState();
    context.read<MembershipBloc>().add(LoadMembershipStatusRequested());
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final initialDate = _selectedDateOfBirth ?? DateTime(now.year - 25, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(eighteenYearsAgo)
          ? eighteenYearsAgo
          : initialDate,
      firstDate: DateTime(1920),
      lastDate: eighteenYearsAgo,
      helpText: 'Select Date of Birth (Must be 18+)',
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _pickFaydaDocument() async {
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
                  'Selected document exceeds the 10MB limit. Please choose a smaller file.',
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your date of birth'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_pickedFile == null || _pickedFile!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please upload your Fayda / National ID document image or PDF',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_agreeToRules) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please accept the Savings & Lending Rules to continue',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final mimeType = _determineMimeType(_pickedFile!.name);
    final int fileSize = _pickedFileSize;

    context.read<MembershipBloc>().add(
      SubmitMembershipApplicationRequested(
        address: _addressController.text.trim(),
        dateOfBirth: _selectedDateOfBirth!,
        phone: _phoneController.text.trim(),
        filePath: _pickedFile!.path!,
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
    final onGradient = ColorConstants.onBrand;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Membership Application'),
        leading: IconButton(
          icon: Icon(AppIcons.back.outline, size: AppSizes.iconM),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.homeScreen);
            }
          },
        ),
      ),
      body: BlocConsumer<MembershipBloc, MembershipState>(
        listener: (context, state) {
          if (state is MembershipSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Application submitted! Ref: ${state.application.applicationNumber}',
                ),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go(AppRoutes.membershipStatus);
          } else if (state is MembershipFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is MembershipStatusLoaded) {
            if (state.hasPendingApplication || state.isActiveMember) {
              context.go(AppRoutes.membershipStatus);
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is MembershipLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding,
                vertical: AppSizes.spacingL,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.spacingL),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            ColorConstants.navGradientStart,
                            ColorConstants.navGradientEnd,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusCard,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join Unity Finance Group',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: onGradient,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSizes.spacingXs),
                          Text(
                            'Become a member to start monthly savings, access flexible lending, and participate in community financial growth.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: onGradient.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXl),
                    Text(
                      'Personal & KYC Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingM),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',
                        prefixIcon: Icon(
                          AppIcons.phone.outline,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: _fieldBorder(),
                        enabledBorder: _fieldBorder(),
                        focusedBorder: _fieldBorder(
                          color: colorScheme.primary,
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Phone number is required'
                          : null,
                    ),
                    const SizedBox(height: AppSizes.spacingM),
                    InkWell(
                      onTap: _pickDateOfBirth,
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusField,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingM,
                          vertical: AppSizes.spacingM,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusField,
                          ),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.calendar.outline,
                              color: colorScheme.primary,
                              size: AppSizes.iconM,
                            ),
                            const SizedBox(width: AppSizes.spacingS),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date of Birth *',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppSizes.spacingXxs,
                                  ),
                                  Text(
                                    _selectedDateOfBirth != null
                                        ? DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(_selectedDateOfBirth!)
                                        : 'Tap to select date',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: _selectedDateOfBirth != null
                                          ? theme.textTheme.bodyLarge?.color
                                          : colorScheme.onSurface
                                              .withValues(alpha: 0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              AppIcons.arrowDown.outline,
                              size: AppSizes.iconS,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingM),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Residential Address / City / Subcity *',
                        prefixIcon: Icon(
                          AppIcons.home.outline,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: _fieldBorder(),
                        enabledBorder: _fieldBorder(),
                        focusedBorder: _fieldBorder(
                          color: colorScheme.primary,
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Residential address is required'
                          : null,
                    ),
                    const SizedBox(height: AppSizes.spacingXl),
                    Text(
                      'Fayda / National ID Document',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXs),
                    Text(
                      'Upload an official Fayda ID or National Passport (PDF, JPEG, or PNG, max 10MB). Your document is securely stored in an encrypted private vault.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                    InkWell(
                      onTap: _pickFaydaDocument,
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusField,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.spacingM),
                        decoration: BoxDecoration(
                          color: _pickedFile != null
                              ? colorScheme.primary.withValues(alpha: 0.05)
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusField,
                          ),
                          border: Border.all(
                            color: _pickedFile != null
                                ? colorScheme.primary
                                : theme.dividerColor,
                            width: _pickedFile != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSizes.spacingS),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _pickedFile != null
                                    ? (_pickedFile!.extension == 'pdf'
                                          ? AppIcons.document.outline
                                          : AppIcons.image.outline)
                                    : AppIcons.upload.outline,
                                color: colorScheme.primary,
                                size: AppSizes.iconL,
                              ),
                            ),
                            const SizedBox(width: AppSizes.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pickedFile != null
                                        ? _pickedFile!.name
                                        : 'Select Fayda ID / Document',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(
                                    height: AppSizes.spacingXxs,
                                  ),
                                  Text(
                                    _pickedFile != null
                                        ? '${(_pickedFileSize / (1024 * 1024)).toStringAsFixed(2)} MB • Tap to replace'
                                        : 'Tap to choose file (PDF, JPG, PNG)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_pickedFile != null)
                              IconButton(
                                icon: Icon(
                                  AppIcons.trash.outline,
                                  size: AppSizes.iconS,
                                ),
                                color: colorScheme.error,
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
                    const SizedBox(height: AppSizes.spacingXl),
                    AppCard(
                      padding: AppSizes.spacingM,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                AppIcons.info.outline,
                                color: colorScheme.primary,
                                size: AppSizes.iconS,
                              ),
                              const SizedBox(width: AppSizes.spacingXs),
                              Text(
                                'Member Commitments',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _bulletItem(
                            'Mandatory Monthly Savings: 2,000 ETB due by the 12th.',
                            theme,
                          ),
                          _bulletItem(
                            'Confidentiality: Accurate identification and contact details required.',
                            theme,
                          ),
                          _bulletItem(
                            'Eligible for member loans after active savings verification.',
                            theme,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingM),
                    CheckboxListTile(
                      value: _agreeToRules,
                      onChanged: (val) =>
                          setState(() => _agreeToRules = val ?? false),
                      title: Text(
                        'I have read and agree to the Unity Finance Group Savings & Lending Rules.',
                        style: theme.textTheme.bodySmall,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSizes.spacingXl),
                    PrimaryButton(
                      label: 'Submit Application',
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSizes.spacingXl),
                  ],
                ),
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

  Widget _bulletItem(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}