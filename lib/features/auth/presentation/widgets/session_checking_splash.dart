import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_images.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/utils/session_expiry_policy.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_event.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_state.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_bloc.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_event.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_state.dart';

/// The authoritative startup screen.
///
/// 1. Enforces the 1-hour session expiry policy.
/// 2. Delegates session validation to [AuthBloc] via [CheckStartupSessionRequested].
/// 3. On [AuthSuccess], delegates membership resolution to [MembershipBloc]
///    via [CheckMembershipAfterAuthRequested].
/// 4. On [MembershipRouteReady], navigates to the resolved destination route.
///
/// No direct use-case calls — all business logic flows through BLoCs.
class SessionCheckingSplash extends StatefulWidget {
  final bool? showOnboarding;

  const SessionCheckingSplash({super.key, this.showOnboarding});

  @override
  State<SessionCheckingSplash> createState() => _SessionCheckingSplashState();
}

class _SessionCheckingSplashState extends State<SessionCheckingSplash> {
  String _statusMessage = 'Checking your session...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _beginStartupCheck());
  }

  Future<void> _beginStartupCheck() async {
    setState(() {
      _hasError = false;
      _statusMessage = 'Checking your session...';
    });

    // 1. Enforce 1-hour session timeout (pure utility, no navigation)
    final hadExpired = await SessionExpiryPolicy.checkAndEnforceExpiry();
    if (hadExpired) {
      if (mounted) context.go(AppRoutes.loginScreen);
      return;
    }

    // 2. Check if any Supabase session exists at all (cold start)
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (!mounted) return;
      final showOnboarding = await _shouldShowOnboarding();
      if (!mounted) return;
      context.go(showOnboarding ? AppRoutes.onboardingScreen : AppRoutes.loginScreen);
      return;
    }

    // 3. Session exists → validate via AuthBloc
    if (mounted) {
      context.read<AuthBloc>().add(CheckStartupSessionRequested());
    }
  }

  Future<bool> _shouldShowOnboarding() async {
    if (widget.showOnboarding != null) return widget.showOnboarding!;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('hasSeenOnboarding') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MultiBlocListener(
      listeners: [
        // ─── AuthBloc listener ───────────────────────────────────────
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              // Auth confirmed → ask MembershipBloc for the routing decision
              setState(() => _statusMessage = 'Verifying membership status...');
              context.read<MembershipBloc>().add(CheckMembershipAfterAuthRequested());
            } else if (state is AuthLoggedOut || state is AuthFailure) {
              // No valid session → login
              context.go(AppRoutes.loginScreen);
            }
          },
        ),

        // ─── MembershipBloc listener ─────────────────────────────────
        BlocListener<MembershipBloc, MembershipState>(
          listener: (context, state) {
            if (state is MembershipRouteReady) {
              SessionExpiryPolicy.recordActivity();
              context.go(state.destinationRoute);
            } else if (state is MembershipFailure) {
              setState(() {
                _hasError = true;
                _statusMessage = state.message;
              });
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorConstants.navyBlue.withValues(alpha: 0.05),
                colorScheme.primary.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AllImages().logo, height: 110),
                  const SizedBox(height: 32),
                  if (!_hasError) ...[
                    CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Icon(AppIcons.warning.outline, size: 48, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: TextStyle(color: colorScheme.error, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.go(AppRoutes.loginScreen),
                          child: const Text('Back to Login'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _beginStartupCheck,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
