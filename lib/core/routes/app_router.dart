import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/features/auth/presentation/screens/forgotPassword.dart';
import 'package:ufg/features/auth/presentation/screens/resetPassword.dart';
import 'package:ufg/features/auth/presentation/screens/welcome_screen.dart';
import 'package:ufg/features/auth/presentation/screens/login_screen.dart';
import 'package:ufg/features/auth/presentation/screens/signup_screen.dart';
import 'package:ufg/features/dashboard/dashboard_wrapper.dart';
import 'package:ufg/features/home/presentation/pages/home_screen.dart';
import 'package:ufg/features/membership/presentation/pages/membership_application_page.dart';
import 'package:ufg/features/membership/presentation/pages/membership_status_page.dart';

class AppRouter {
  final bool showOnboarding;
  AppRouter({required this.showOnboarding});
  // Global navigator key is useful for specialized dialogs/snackbars
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: showOnboarding
        ? AppRoutes.onboardingScreen
        : AppRoutes.loginScreen,
    routes: [
      GoRoute(
        path: AppRoutes.onboardingScreen,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.loginScreen,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupScreen,
        builder: (_, _) => const SignupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardWrapper(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeScreen,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordScreen,
        builder: (_, _) => ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPasswordScreen,
        builder: (_, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.membershipApply,
        builder: (_, _) => const MembershipApplicationPage(),
      ),
      GoRoute(
        path: AppRoutes.membershipStatus,
        builder: (_, _) => const MembershipStatusPage(),
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                color: Theme.of(context).colorScheme.onSurface,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'erRoR',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),
        body: Center(child: Text('Error: ${state.error}')),
      );
    },
  );
}

