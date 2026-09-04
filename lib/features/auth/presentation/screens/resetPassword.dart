import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:otp_text_field/otp_text_field.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_state.dart';
import 'package:ufg/features/auth/presentation/widgets/auth_shared.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String _otp = '';
  bool _isOtpVerified = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLoading = context.select<AuthBloc, bool>(
      (bloc) => bloc.state is AuthLoading,
    );
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PasswordResetOtpVerified) {
            setState(() => _isOtpVerified = true);
          } else if (state is ResetPasswordSent) {
            _showMessage('Your password has been reset. Please sign in.');
            context.go(AppRoutes.loginScreen);
          } else if (state is AuthFailure) {
            _showMessage(state.message, isError: true);
          }
        },
        child: AuthBackdrop(
          child: SafeArea(
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
                        onPressed: () =>
                            context.go(AppRoutes.forgotPasswordScreen),
                        icon: Icon(
                          AppIcons.back.outline,
                          color: colorScheme.primary,
                        ),
                        tooltip: 'Back',
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      _ProgressIndicator(
                        isPasswordStep: _isOtpVerified,
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                      const SizedBox(height: AppSizes.spacingXxl),
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: _isOtpVerified
                              ? ColorConstants.brandGreen.withValues(alpha: 0.1)
                              : colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(21),
                        ),
                        child: Icon(
                          _isOtpVerified
                              ? AppIcons.lock.outline
                              : AppIcons.mail.outline,
                          color: colorScheme.primary,
                          size: 31,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      AuthHeadline(
                        text: _isOtpVerified
                            ? 'Create a new\npassword'
                            : 'Check your\nemail',
                      ),
                      const SizedBox(height: AppSizes.spacingS),
                      Text(
                        _isOtpVerified
                            ? 'Choose a strong password that you do not use elsewhere.'
                            : 'We sent a 6-digit verification code to ${widget.email}.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingXxl),
                      _buildForm(isLoading, theme, colorScheme),
                      const SizedBox(height: AppSizes.sectionGap),
                      if (!_isOtpVerified)
                        Center(
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => context.go(
                                    AppRoutes.forgotPasswordScreen,
                                  ),
                            child: Text(
                              'Use a different email address',
                              style: TextStyle(
                                color: colorScheme.primary,
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
      ),
    );
  }

  Widget _buildForm(bool isLoading, ThemeData theme, ColorScheme colorScheme) {
    return AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isOtpVerified) ...[
            Text(
              'Verification code',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.spacingM),
            OTPTextField(
              length: 6,
              width: MediaQuery.sizeOf(context).width - 96,
              textFieldAlignment: MainAxisAlignment.spaceBetween,
              fieldWidth: 42,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              onCompleted: (code) => _otp = code,
            ),
            const SizedBox(height: AppSizes.spacingS),
            Text(
              'The code expires shortly for your security.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ] else ...[
            _passwordField(
              controller: _passwordCtrl,
              label: 'New password',
              obscureText: _obscurePassword,
              onVisibilityChanged: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              theme: theme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: AppSizes.spacingM),
            _passwordField(
              controller: _confirmPasswordCtrl,
              label: 'Confirm new password',
              obscureText: _obscureConfirmation,
              onVisibilityChanged: () {
                setState(() => _obscureConfirmation = !_obscureConfirmation);
              },
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
          const SizedBox(height: AppSizes.spacingXl),
          PrimaryButton(
            label: _isOtpVerified ? 'Save new password' : 'Verify code',
            isLoading: isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onVisibilityChanged,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      autofillHints: const [AutofillHints.newPassword],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          AppIcons.lock.outline,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        suffixIcon: IconButton(
          onPressed: onVisibilityChanged,
          icon: Icon(
            obscureText ? AppIcons.eyeOff.outline : AppIcons.eye.outline,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          tooltip: obscureText ? 'Show password' : 'Hide password',
        ),
        filled: true,
        fillColor: colorScheme.surface,
        border: _fieldBorder(),
        enabledBorder: _fieldBorder(),
        focusedBorder: _fieldBorder(color: colorScheme.primary),
      ),
    );
  }

  OutlineInputBorder _fieldBorder({Color color = Colors.transparent}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusField),
      borderSide: BorderSide(color: color, width: 1.4),
    );
  }

  void _submit() {
    if (!_isOtpVerified) {
      if (widget.email.isEmpty || _otp.length != 6) {
        _showMessage('Enter the 6-digit code from your email.', isError: true);
        return;
      }
      context.read<AuthBloc>().add(
        VerifyPasswordResetOtpRequested(widget.email, _otp),
      );
      return;
    }

    if (_passwordCtrl.text.length < 6) {
      _showMessage(
        'Use at least 6 characters for your password.',
        isError: true,
      );
      return;
    }
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      _showMessage('Passwords do not match. Please try again.', isError: true);
      return;
    }
    context.read<AuthBloc>().add(
      ResetPasswordRequested(widget.email, _passwordCtrl.text),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.isPasswordStep,
    required this.colorScheme,
    required this.theme,
  });

  final bool isPasswordStep;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _step('1', 'Verify', isComplete: isPasswordStep),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: isPasswordStep
                ? colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        _step('2', 'Reset', isActive: isPasswordStep),
      ],
    );
  }

  Widget _step(
    String number,
    String label, {
    bool isActive = false,
    bool isComplete = false,
  }) {
    final highlighted = isActive || isComplete;
    return Row(
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlighted
                ? colorScheme.primary
                : theme.dividerColor,
            shape: BoxShape.circle,
          ),
          child: Text(
            isComplete ? '\u2713' : number,
            style: TextStyle(
              color: highlighted
                  ? ColorConstants.onBrand
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: highlighted
                ? theme.textTheme.bodyLarge?.color
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}