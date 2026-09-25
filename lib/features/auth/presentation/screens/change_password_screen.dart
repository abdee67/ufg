import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/utils/password_policy.dart';
import 'package:ufg/core/utils/app_state_notifier.dart';
import 'package:ufg/core/widgets/custom_textField.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_state.dart';
import 'package:ufg/features/auth/presentation/widgets/auth_shared.dart';
import 'package:ufg/features/auth/presentation/widgets/password_visibility_toggle.dart';
import 'package:ufg/injection_container.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PasswordChanged) {
            getit<AppStateNotifier>().clearPasswordChangeRequirement();
            context.go(AppRoutes.initialRoute);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) => AuthBackdrop(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.maxContentWidth,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthLogoLockup(),
                        const SizedBox(height: 48),
                        const AuthHeadline(text: 'Create a new\npassword'),
                        const SizedBox(height: AppSizes.spacingS),
                        Text(
                          'Your temporary password can only be used to set a new password.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSizes.sectionGap),
                        AuthCard(
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: _password,
                                label: 'New password',
                                icon: AppIcons.lock.outline,
                                obscureText: _obscurePassword,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                validator: (value) =>
                                    PasswordPolicy.validationMessage(
                                      value ?? '',
                                    ),
                                suffixIcon: PasswordVisibilityToggle(
                                  visible: !_obscurePassword,
                                  onToggle: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.fieldGap),
                              CustomTextField(
                                controller: _confirm,
                                label: 'Confirm new password',
                                icon: AppIcons.lock.outline,
                                obscureText: _obscureConfirm,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                validator: (value) => value != _password.text
                                    ? 'Passwords do not match'
                                    : null,
                                suffixIcon: PasswordVisibilityToggle(
                                  visible: !_obscureConfirm,
                                  onToggle: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.sectionGap),
                              PrimaryButton(
                                label: 'Save new password',
                                isLoading: state is AuthLoading,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(ChangePasswordRequested(_password.text));
    }
  }
}
