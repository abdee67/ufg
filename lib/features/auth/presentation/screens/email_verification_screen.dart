import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_images.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/primary_button.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_state.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback? onVerified;
  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.onVerified,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  String? _message;
  final _otpController = TextEditingController();
  int _countdown = 0;
  Timer? _timer;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpVerified) {
            if (widget.onVerified != null) {
              widget.onVerified!();
            } else {
              context.go(AppRoutes.membershipApply);
            }
          } else if (state is OtpSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('New code sent to your email!'),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _startCountdown();
          } else if (state is AuthFailure) {
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
          return Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(AppSizes.spacingL),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingXxl,
                  vertical: AppSizes.spacingHero,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSheet),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(AllImages().logo, height: 120),
                    const SizedBox(height: AppSizes.spacingL),
                    Text(
                      'Verify your email',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXs),
                    Text(
                      'We sent an 8-digit code to:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingXl),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _otpController,
                            decoration: InputDecoration(
                              labelText: 'Verification code',
                              prefixIcon: Icon(
                                AppIcons.shield.outline,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                              filled: true,
                              fillColor: colorScheme.surface,
                              border: _fieldBorder(),
                              enabledBorder: _fieldBorder(),
                              focusedBorder: _fieldBorder(
                                color: colorScheme.primary,
                              ),
                              counterText: '',
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 8,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the verification code';
                              }
                              if (value.length != 8) {
                                return 'Code must be 8 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSizes.spacingL),
                          if (_message != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSizes.spacingXs,
                              ),
                              child: Text(
                                _message!,
                                style: TextStyle(
                                  color: _message!.contains('failed')
                                      ? colorScheme.error
                                      : ColorConstants.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          PrimaryButton(
                            label: 'Verify',
                            isLoading: state is AuthLoading,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthBloc>().add(
                                  VerifyOtpRequested(
                                    widget.email,
                                    _otpController.text.trim(),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: AppSizes.spacingM),
                          TextButton(
                            onPressed: _countdown == 0
                                ? () {
                                    context.read<AuthBloc>().add(
                                      SendOtpRequested(widget.email),
                                    );
                                  }
                                : null,
                            child: Text(
                              _countdown == 0
                                  ? 'Resend code'
                                  : 'Resend in $_countdown seconds',
                              style: TextStyle(
                                color: _countdown == 0
                                    ? colorScheme.primary
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.45),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.spacingXs),
                          TextButton(
                            onPressed: () =>
                                context.go(AppRoutes.loginScreen),
                            child: Text(
                              'Back to sign in',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
}