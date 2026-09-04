import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_state.dart';
import 'package:ufg/features/auth/presentation/widgets/auth_shared.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ForgotPasswordSent) {
            final email = Uri.encodeQueryComponent(_emailCtrl.text.trim());
            context.go('${AppRoutes.resetPasswordScreen}?email=$email');
          } else if (state is AuthFailure) {
            _showMessage(state.message, isError: true);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return AuthBackdrop(
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
                          onPressed: () => context.go(AppRoutes.loginScreen),
                          icon: Icon(
                            AppIcons.back.outline,
                            color: colorScheme.primary,
                          ),
                          tooltip: 'Back to login',
                        ),
                        const SizedBox(height: 26),
                        const AuthLogoLockup(),
                        const SizedBox(height: 30),
                        const AuthHeadline(text: 'Forgot your\npassword?'),
                        const SizedBox(height: 14),
                        Text(
                          'Enter your email and we\'ll send a secure code to help you get back into your account.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        AuthCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email address',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _sendResetCode(),
                                decoration: InputDecoration(
                                  hintText: 'you@example.com',
                                  prefixIcon: Icon(
                                    AppIcons.mail.outline,
                                    color: colorScheme.primary,
                                  ),
                                  filled: true,
                                  fillColor: theme.cardColor,
                                  border: _fieldBorder(),
                                  enabledBorder: _fieldBorder(),
                                  focusedBorder: _fieldBorder(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              PrimaryButton(
                                label: 'Send verification code',
                                isLoading: isLoading,
                                onPressed: _sendResetCode,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.sectionGap),
                        Center(
                          child: TextButton(
                            onPressed: () => context.go(AppRoutes.loginScreen),
                            child: Text(
                              'Back to sign in',
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

  void _sendResetCode() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Enter a valid email address.', isError: true);
      return;
    }
    context.read<AuthBloc>().add(ForgotPasswordRequested(email));
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