import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/constants/session_constants.dart';
import 'package:ufg/core/utils/session_expiry_policy.dart';
import 'package:ufg/core/widgets/custom_textField.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_state.dart';
import 'package:ufg/features/auth/presentation/widgets/auth_shared.dart';
import 'package:ufg/features/auth/presentation/widgets/password_visibility_toggle.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_bloc.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_event.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isCheckingMembership = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hadNotice = await SessionExpiryPolicy.consumeExpiredNotice();
      if (hadNotice && mounted) {
        _message(SessionConstants.expiredNoticeMessage, false);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthSuccess) {
                setState(() => _isCheckingMembership = true);
                context.read<MembershipBloc>().add(
                  CheckMembershipAfterAuthRequested(),
                );
              } else if (state is AuthFailure) {
                setState(() => _isCheckingMembership = false);
                _message(state.message, true);
              }
            },
          ),
          BlocListener<MembershipBloc, MembershipState>(
            listener: (context, state) {
              if (state is MembershipRouteReady) {
                setState(() => _isCheckingMembership = false);
                SessionExpiryPolicy.recordActivity();
                context.go(state.destinationRoute);
              } else if (state is MembershipFailure) {
                setState(() => _isCheckingMembership = false);
                context.go(AppRoutes.membershipStatus);
              }
            },
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading || _isCheckingMembership;

            return AuthBackdrop(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.screenPadding),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AuthLogoLockup(),
                          const SizedBox(height: 48),
                          const AuthHeadline(text: 'Welcome\nback'),
                          const SizedBox(height: AppSizes.spacingS),
                          Text(
                            'Sign in to continue your financial journey with Unity Finance.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          AuthCard(
                            child: Column(
                              children: [
                                CustomTextField(
                                  controller: _emailController,
                                  label: 'Email address',
                                  icon: AppIcons.mail.outline,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                ),
                                const SizedBox(height: AppSizes.fieldGap),
                                CustomTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: AppIcons.lock.outline,
                                  obscureText: _obscurePassword,
                                  autofillHints: const [AutofillHints.password],
                                  suffixIcon: PasswordVisibilityToggle(
                                    visible: !_obscurePassword,
                                    onToggle: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => context.go(
                                      AppRoutes.forgotPasswordScreen,
                                    ),
                                    child: Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                PrimaryButton(
                                  label: 'Sign in',
                                  isLoading: isLoading,
                                  onPressed: _login,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.spacingL),
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  context.go(AppRoutes.outsiderLoanApply),
                              child: Text(
                                'Need a loan but not a member? Apply as an outsider',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  context.go(AppRoutes.signupScreen),
                              child: Text(
                                'New to Unity Finance?  Create an account',
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
            );
          },
        ),
      ),
    );
  }

  void _login() {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _message('Enter your email and password.', true);
      return;
    }
    context.read<AuthBloc>().add(
      SignInRequested(_emailController.text.trim(), _passwordController.text),
    );
  }

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
