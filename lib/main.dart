import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/routes/app_router.dart';
import 'package:ufg/core/theme/app_theme.dart';
import 'package:ufg/core/utils/app_state_notifier.dart';
import 'package:ufg/core/utils/session_expiry_policy.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_bloc.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:ufg/injection_container.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/env/.env");
  await SupabaseConfig.init();
  initDependency(); // initializing getit for dependency injection

  // Check and enforce 1-hour session expiry on cold start before app mounts
  await SessionExpiryPolicy.checkAndEnforceExpiry();

  runApp(
    ChangeNotifierProvider(
      create: (context) => getit<AppStateNotifier>(),
      child: const UFG(),
    ),
  );
}

class UFG extends StatefulWidget {
  const UFG({super.key});
  @override
  State<UFG> createState() => _UFGState();
}

class _UFGState extends State<UFG> with WidgetsBindingObserver {
  bool showOnboarding = true;
  bool isLoading = true;
  late GoRouter _router;
  bool _routerReady = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForForcedLogout();
    _checkOnboardingStatus();
  }

  void _listenForForcedLogout() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == AuthChangeEvent.signedOut && _routerReady) {
          _router.go(AppRoutes.loginScreen);
        }
      },
      onError: (Object error) {
        if (kDebugMode) {
          debugPrint('Auth state stream error (ignored): $error');
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(SessionExpiryPolicy.markBackgrounded());
        break;
      case AppLifecycleState.resumed:
        unawaited(_enforceSessionExpiry());
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _enforceSessionExpiry() async {
    final hadExpired = await SessionExpiryPolicy.checkAndEnforceExpiry();
    if (hadExpired && _routerReady) {
      _router.go(AppRoutes.loginScreen);
    }
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      setState(() {
        showOnboarding = !hasSeenOnboarding;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        showOnboarding = true;
        isLoading = false;
      });
    }

    _router = AppRouter(showOnboarding: showOnboarding).router;
    _routerReady = true;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MultiProvider(
      providers: [
        BlocProvider(create: (context) => getit<AuthBloc>()),
        BlocProvider(create: (context) => getit<MembershipBloc>()),
        BlocProvider(create: (context) => getit<SavingsBloc>()),
        ChangeNotifierProvider(create: (context) => getit<AppStateNotifier>()),
      ],
      child: Consumer<AppStateNotifier>(
        builder: (context, appState, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Unity Finance Group',
            routerConfig: _router,
            theme: ThemeConfig.lightTheme,
            darkTheme: ThemeConfig.darkTheme,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          );
        },
      ),
    );
  }
}
