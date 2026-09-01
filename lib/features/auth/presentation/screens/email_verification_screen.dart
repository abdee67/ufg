import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_images.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'dart:async';
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
              ),
            );
            _startCountdown();
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.05),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 40,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(AllImages().logo, height: 120),
                      const SizedBox(height: 20),
                      Text(
                        'Verify Your Email',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We sent a 8-digit code to:',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.email,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _otpController,
                              decoration: InputDecoration(
                                labelText: 'Verification Code',
                                prefixIcon: Icon(
                                  Icons.verified_user,
                                  color: colorScheme.primary,
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
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
                            const SizedBox(height: 20),
                            if (_message != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  _message!,
                                  style: TextStyle(
                                    color: _message!.contains('failed')
                                        ? colorScheme.error
                                        : ColorConstants.brandGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 5,
                                ),
                                child: state is AuthLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'VERIFY',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 15),
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
                                    ? 'Resend Code'
                                    : 'Resend in $_countdown seconds',
                                style: TextStyle(
                                  color: _countdown == 0
                                      ? colorScheme.primary
                                      : theme.hintColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => context.go(AppRoutes.loginScreen),
                              child: Text(
                                'Back to Login',
                                style: TextStyle(color: colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
