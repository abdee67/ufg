import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ufg/core/constants/app_icons.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/constants/app_sizes.dart';
import 'package:ufg/core/widgets/error_state.dart';
import 'package:ufg/features/auth/presentation/screens/forgotPassword.dart';
import 'package:ufg/features/auth/presentation/screens/resetPassword.dart';
import 'package:ufg/features/auth/presentation/screens/welcome_screen.dart';
import 'package:ufg/features/auth/presentation/screens/login_screen.dart';
import 'package:ufg/features/auth/presentation/screens/signup_screen.dart';
import 'package:ufg/features/auth/presentation/widgets/session_checking_splash.dart';
import 'package:ufg/features/dashboard/dashboard_wrapper.dart';
import 'package:ufg/features/home/presentation/bloc/home_bloc.dart';
import 'package:ufg/features/home/presentation/pages/home_screen.dart';
import 'package:ufg/features/home/presentation/pages/search_screen.dart';
import 'package:ufg/features/membership/presentation/pages/membership_application_page.dart';
import 'package:ufg/features/membership/presentation/pages/membership_status_page.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_bloc.dart';
import 'package:ufg/features/loans/presentation/pages/guarantor_requests_page.dart';
import 'package:ufg/features/loans/presentation/pages/loan_application_page.dart';
import 'package:ufg/features/loans/presentation/pages/loan_application_status_page.dart';
import 'package:ufg/features/loans/presentation/pages/loan_detail_page.dart';
import 'package:ufg/features/loans/presentation/pages/loan_extension_page.dart';
import 'package:ufg/features/loans/presentation/pages/loan_repayment_page.dart';
import 'package:ufg/features/loans/presentation/pages/loans_page.dart';
import 'package:ufg/features/loans/presentation/pages/outsider_loan_application_page.dart';
import 'package:ufg/features/savings/domain/entities/savings_obligation_entity.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:ufg/features/savings/presentation/pages/savings_history_page.dart';
import 'package:ufg/features/savings/presentation/pages/savings_obligation_page.dart';
import 'package:ufg/features/savings/presentation/pages/savings_page.dart';
import 'package:ufg/features/savings/presentation/pages/savings_payment_page.dart';
import 'package:ufg/features/savings/presentation/pages/withdrawal_history_page.dart';
import 'package:ufg/features/savings/presentation/pages/withdrawal_page.dart';
import 'package:ufg/injection_container.dart';

class AppRouter {
  final bool showOnboarding;
  AppRouter({required this.showOnboarding});
  // Global navigator key is useful for specialized dialogs/snackbars
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.initialRoute,
    routes: [
      GoRoute(
        path: AppRoutes.initialRoute,
        builder: (context, state) =>
            SessionCheckingSplash(showOnboarding: showOnboarding),
      ),
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
      GoRoute(
        path: AppRoutes.outsiderLoanApply,
        builder: (_, _) => BlocProvider(
          create: (_) => getit<LoanBloc>(),
          child: const OutsiderLoanApplicationPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.searchScreen,
        builder: (context, state) => BlocProvider(
          create: (_) => getit<HomeBloc>(),
          child: const SearchScreen(),
        ),
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
                builder: (_, _) => BlocProvider(
                  create: (_) => getit<HomeBloc>(),
                  child: const HomeScreen(),
                ),
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

      // =================== Savings Feature Routes ===================
      GoRoute(
        path: AppRoutes.savings,
        builder: (_, _) => BlocProvider(
          create: (_) => getit<SavingsBloc>(),
          child: const SavingsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.savingsObligations,
        builder: (_, _) => BlocProvider(
          create: (_) => getit<SavingsBloc>(),
          child: const SavingsObligationPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.savingsHistory,
        builder: (_, _) => BlocProvider(
          create: (_) => getit<SavingsBloc>(),
          child: const SavingsHistoryPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.savingsWithdraw,
        builder: (_, _) => BlocProvider(
          create: (_) => getit<SavingsBloc>(),
          child: const WithdrawalPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.savingsWithdrawals,
        builder: (_, _) => BlocProvider(
          create: (_) => getit<SavingsBloc>(),
          child: const WithdrawalHistoryPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.savingsPayment,
        builder: (_, state) => BlocProvider(
          create: (_) => getit<SavingsBloc>(),
          child: SavingsPaymentPage(
            obligation: state.extra is SavingsObligationEntity
                ? state.extra as SavingsObligationEntity
                : null,
          ),
        ),
      ),

      // =================== Loan Feature Routes ===================
      GoRoute(
        path: AppRoutes.loans,
        builder: (_, _) => BlocProvider(
          create: (_) => getit<LoanBloc>(),
          child: const LoansPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.loanApply,
        builder: (_, _) => BlocProvider(
          create: (_) => getit<LoanBloc>(),
          child: const LoanApplicationPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.loanApplicationStatus,
        builder: (_, state) => BlocProvider(
          create: (_) => getit<LoanBloc>(),
          child: LoanApplicationStatusPage(
            applicationId: state.pathParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.loanDetail,
        builder: (_, state) => BlocProvider(
          create: (_) => getit<LoanBloc>(),
          child: LoanDetailPage(loanId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.loanRepay,
        builder: (_, state) => BlocProvider(
          create: (_) => getit<LoanBloc>(),
          child: LoanRepaymentPage(loanId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.loanGuarantors,
        builder: (_, _) => BlocProvider(
          create: (_) => getit<LoanBloc>(),
          child: const GuarantorRequestsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.loanExtension,
        builder: (_, state) => BlocProvider(
          create: (_) => getit<LoanBloc>(),
          child: LoanExtensionPage(loanId: state.pathParameters['id'] ?? ''),
        ),
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Page not found'),
          leading: IconButton(
            icon: Icon(AppIcons.back.outline, size: AppSizes.iconM),
            tooltip: 'Back',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(AppRoutes.homeScreen);
              }
            },
          ),
        ),
        body: ErrorState(
          title: 'Page not found',
          message: 'The page you are looking for does not exist.',
        ),
      );
    },
  );
}
