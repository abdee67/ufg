import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/constants/app_text_styles.dart';
import 'package:ufg/core/widgets/custom_textField.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_state.dart';
import 'package:ufg/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:ufg/features/auth/presentation/widgets/auth_shared.dart';
import 'package:ufg/features/auth/presentation/widgets/password_visibility_toggle.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController(),
      _fullName = TextEditingController(),
      _phone = TextEditingController();
  bool _obscurePassword = true, _obscureConfirm = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _fullName.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is EmailVerificationSent) _showVerification();
          if (state is AuthFailure) _message(_cleanError(state.message), true);
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return AuthBackdrop(
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.screenPadding,
                      14,
                      AppSizes.screenPadding,
                      32,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => context.go(AppRoutes.loginScreen),
                            icon: Icon(
                              AppIcons.back.outline,
                              color: theme.colorScheme.primary,
                            ),
                            tooltip: 'Back to sign in',
                          ),
                          const SizedBox(height: AppSizes.spacingS),
                          const AuthLogoLockup(),
                          const SizedBox(height: AppSizes.sectionGap),
                          const AuthHeadline(text: 'Create your\naccount'),
                          const SizedBox(height: AppSizes.spacingS),
                          Text(
                            'Join Unity Finance Group to begin your savings and financial growth.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSizes.sectionGap),
                          AuthCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personal Details',
                                  style: AppTextStyles.sectionTitle(context),
                                ),
                                const SizedBox(height: AppSizes.spacingM),
                                CustomTextField(
                                  controller: _fullName,
                                  label: 'Full Name',
                                  icon: AppIcons.user.outline,
                                  autofillHints: const [AutofillHints.name],
                                  validator: (value) =>
                                      _validateRequired(value, 'Full Name'),
                                ),
                                const SizedBox(height: AppSizes.spacingM),
                                CustomTextField(
                                  controller: _phone,
                                  label: 'Phone Number',
                                  icon: AppIcons.phone.outline,
                                  keyboardType: TextInputType.phone,
                                  autofillHints: const [AutofillHints.telephoneNumber],
                                  validator: (value) =>
                                      _validateRequired(value, 'Phone Number'),
                                ),
                                const SizedBox(height: AppSizes.spacingM),
                                CustomTextField(
                                  controller: _email,
                                  label: 'Email Address',
                                  icon: AppIcons.mail.outline,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  validator: (value) {
                                    final text = value?.trim() ?? '';
                                    if (text.isEmpty) return 'Please enter Email Address';
                                    if (!text.contains('@')) return 'Enter a valid email address';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSizes.spacingXl),
                                Text(
                                  'Security',
                                  style: AppTextStyles.sectionTitle(context),
                                ),
                                const SizedBox(height: AppSizes.spacingM),
                                CustomTextField(
                                  controller: _password,
                                  label: 'Password',
                                  icon: AppIcons.lock.outline,
                                  obscureText: _obscurePassword,
                                  autofillHints: const [AutofillHints.newPassword],
                                  validator: (value) {
                                    final text = value ?? '';
                                    if (text.isEmpty) return 'Please enter Password';
                                    if (text.length < 6) return 'Use at least 6 characters';
                                    return null;
                                  },
                                  suffixIcon: PasswordVisibilityToggle(
                                    visible: !_obscurePassword,
                                    onToggle: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSizes.spacingM),
                                CustomTextField(
                                  controller: _confirm,
                                  label: 'Confirm Password',
                                  icon: AppIcons.lock.outline,
                                  obscureText: _obscureConfirm,
                                  validator: (value) {
                                    final text = value ?? '';
                                    if (text.isEmpty) return 'Please enter Confirm Password';
                                    if (text != _password.text) return 'Passwords do not match';
                                    return null;
                                  },
                                  suffixIcon: PasswordVisibilityToggle(
                                    visible: !_obscureConfirm,
                                    onToggle: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 26),
                                PrimaryButton(
                                  label: 'Create Account',
                                  isLoading: loading,
                                  onPressed: _submit,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.spacingM),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go(AppRoutes.loginScreen),
                              child: Text(
                                'Already have an account?  Sign in',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String? _validateRequired(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter $label';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          SignUpRequested(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _fullName.text.trim(),
            phone: _phone.text.trim(),
          ),
        );
  }

  void _showVerification() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => EmailVerificationScreen(
          email: _email.text.trim(),
          onVerified: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Account verified! Please complete your membership application.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go(AppRoutes.membershipApply);
          },
        ),
      );

  String _cleanError(String message) =>
      message.replaceFirst(RegExp(r'^Exception: '), '');

  void _message(String message, bool error) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
}