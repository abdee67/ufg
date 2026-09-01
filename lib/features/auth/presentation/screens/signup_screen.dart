import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_images.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_state.dart';
import 'package:ufg/features/auth/presentation/screens/email_verification_screen.dart';

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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is EmailVerificationSent) _showVerification();
            if (state is AuthFailure) _message(_cleanError(state.message), true);
          },
          builder: (context, state) {
            final loading = state is AuthLoading;
            return Stack(
              children: [
                const _SignupBackdrop(),
                SafeArea(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.screenPadding,
                        14,
                        AppSizes.screenPadding,
                        32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => context.go(AppRoutes.loginScreen),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          const _SignupBrand(),
                          const SizedBox(height: 28),
                          Text(
                            'Create your\naccount',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: AppSizes.headingSize,
                              height: 1.08,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Join Unity Finance Group to begin your savings and financial growth.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _SignupCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle('Personal Details'),
                                const SizedBox(height: 16),
                                _field(
                                  _fullName,
                                  'Full Name',
                                  Icons.person_outline_rounded,
                                  required: true,
                                ),
                                const SizedBox(height: 16),
                                _field(
                                  _phone,
                                  'Phone Number',
                                  Icons.phone_outlined,
                                  type: TextInputType.phone,
                                  required: true,
                                ),
                                const SizedBox(height: 16),
                                _field(
                                  _email,
                                  'Email Address',
                                  Icons.mail_outline_rounded,
                                  type: TextInputType.emailAddress,
                                  required: true,
                                  email: true,
                                ),
                                const SizedBox(height: 24),
                                const _SectionTitle('Security'),
                                const SizedBox(height: 16),
                                _field(
                                  _password,
                                  'Password',
                                  Icons.lock_outline_rounded,
                                  required: true,
                                  obscure: _obscurePassword,
                                  suffix: IconButton(
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _field(
                                  _confirm,
                                  'Confirm Password',
                                  Icons.lock_outline_rounded,
                                  required: true,
                                  obscure: _obscureConfirm,
                                  suffix: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                  match: true,
                                ),
                                const SizedBox(height: 26),
                                SizedBox(
                                  width: double.infinity,
                                  height: AppSizes.buttonHeight,
                                  child: ElevatedButton(
                                    onPressed: loading ? null : _submit,
                                    style: Theme.of(context)
                                        .elevatedButtonTheme
                                        .style,
                                    child: loading
                                        ? const _SignupLoader()
                                        : const Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go(AppRoutes.loginScreen),
                              child: Text(
                                'Already have an account?  Sign in',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
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
              ],
            );
          },
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    bool email = false,
    bool obscure = false,
    bool match = false,
    TextInputType? type,
    Widget? suffix,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return 'Please enter $label';
          if (email && !text.contains('@')) return 'Enter a valid email address';
          if (controller == _password && text.length < 6) {
            return 'Use at least 6 characters';
          }
          if (match && text != _password.text) return 'Passwords do not match';
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          suffixIcon: suffix,
          filled: true,
          fillColor: Theme.of(context).colorScheme.inversePrimary,
          border: _inputBorder(),
          enabledBorder: _inputBorder(),
          focusedBorder: _inputBorder(Theme.of(context).colorScheme.primary),
        ),
      );

  OutlineInputBorder _inputBorder([Color color = Colors.transparent]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
        borderSide: BorderSide(color: color, width: 1.4),
      );

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

class _SignupBackdrop extends StatelessWidget {
  const _SignupBackdrop();
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -100,
              child: _circle(Theme.of(context).colorScheme.primary, 285),
            ),
            Positioned(
              bottom: -130,
              left: -85,
              child: _circle(Theme.of(context).colorScheme.primary, 265),
            ),
          ],
        ),
      );
  Widget _circle(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _SignupBrand extends StatelessWidget {
  const _SignupBrand();
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Color(0x16000000), blurRadius: 14),
              ],
            ),
            child: Image.asset(AllImages().logo),
          ),
          const SizedBox(width: 12),
          Text(
            'Unity Finance',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}

class _SignupCard extends StatelessWidget {
  const _SignupCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .93),
          borderRadius: BorderRadius.circular(AppSizes.pageRadius),
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      );
}

class _SignupLoader extends StatelessWidget {
  const _SignupLoader();
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      );
}
