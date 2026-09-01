import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_images.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_state.dart';
import 'package:ufg/features/auth/presentation/widgets/session_checking_splash.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration.zero, () {
      if (mounted) context.read<AuthBloc>().add(CheckStartupSessionRequested());
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.go(AppRoutes.membershipStatus);
          } else if (state is AuthLoggedOut) {
            setState(() => _isCheckingSession = false);
          } else if (state is AuthFailure) {
            setState(() => _isCheckingSession = false);
            _message(state.message, true);
          }
        },
        builder: (context, state) {
          if (_isCheckingSession) return const SessionCheckingSplash();
          return _AuthBackdrop(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LogoLockup(),
                    const SizedBox(height: 58),
                    Text(
                      'Welcome\nback',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: AppSizes.headingSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sign in to continue your financial journey with Unity Finance.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _AuthCard(
                      child: Column(
                        children: [
                          _input(
                            controller: _emailController,
                            label: 'Email address',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: AppSizes.fieldGap),
                          _input(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffix: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  context.go(AppRoutes.forgotPasswordScreen),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: AppSizes.buttonHeight,
                            child: ElevatedButton(
                              onPressed: state is AuthLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Theme.of(context).colorScheme.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: state is AuthLoading
                                  ? const _Loader()
                                  : const Text('Sign in', style: _buttonText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.signupScreen),
                        child:  Text(
                          'New to Unity Finance?  Create an account',
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
          );
        },
      ),
    );
  }

  Widget _input({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType? keyboardType,
  bool obscureText = false,
  Widget? suffix,
}) => TextField(
  controller: controller,
  keyboardType: keyboardType,
  obscureText: obscureText,
  decoration: InputDecoration(
    labelText: label,
    labelStyle:  TextStyle(color: Theme.of(context).colorScheme.primary),
    prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
    suffixIcon: suffix,
    filled: true,
    fillColor: Theme.of(context).colorScheme.inverseSurface,
    border: _border(),
    enabledBorder: _border(),
    focusedBorder: _border(Theme.of(context).colorScheme.primary),
  ),
);
OutlineInputBorder _border([Color color = Colors.transparent]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
      borderSide: BorderSide(color: color, width: 1.4),
    );

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
          backgroundColor: error ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
}

const _buttonText = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(top: -110, right: -100, child: _circle(Theme.of(context).colorScheme.primary, 285)),
      Positioned(bottom: -135, left: -90, child: _circle(Theme.of(context).colorScheme.primary, 265)),
      child,
    ],
  );
  Widget _circle(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _LogoLockup extends StatelessWidget {
  const _LogoLockup();
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

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.child});
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



class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 22,
    height: 22,
    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
  );
}
