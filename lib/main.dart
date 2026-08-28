import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:ufg/injection_container.dart';
import 'core/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 // await dotenv.load(fileName: "assets/.env");
  await SupabaseConfig.init();
  initDependency(); //initializing getit for dependency injection
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

    ///this suppose to be in splash screen but for now i will put it here to avoid creating another screen just for this purpose
  }

  /// Redirect to the login screen whenever the user becomes signed out, whether
  /// that was a manual sign-out or the client-side expiry policy calling
  /// [SupabaseClient.auth.signOut]. Signing out wipes the local session storage,
  /// so there is nothing to auto-log-in with on the next launch.
  void _listenForForcedLogout() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == AuthChangeEvent.signedOut && _routerReady) {
          _router.go(AppRoutes.loginScreen);
        }
      },
      onError: (Object error) {
        // gotrue pushes token-refresh failures onto this stream (e.g.
        // AuthRetryableFetchException when the network is flaky as the app
        // resumes). Without an onError handler these become unhandled
        // exceptions that crash the app. They are transient and gotrue retries
        // on its own, so keep the session and just log in debug.
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
        // Left the foreground: stamp the time so we can measure the gap on wake.
        unawaited(SessionExpiryPolicy.markBackgrounded());
        break;
      case AppLifecycleState.resumed:
        // Back in the foreground: enforce the login wall if we were away too
        // long. Active users never reach here mid-use, so they are untouched.
        unawaited(_enforceSessionExpiry());
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _enforceSessionExpiry() async {
    final auth = Supabase.instance.client.auth;
    final expired = await SessionExpiryPolicy.hasExpiredWhileBackgrounded();
    await SessionExpiryPolicy.clear();
    if (expired && auth.currentSession != null) {
      // Local scope clears secure storage and emits signedOut without a network
      // call, so it works even on a flaky connection after a long background.
      // The onAuthStateChange listener turns signedOut into a login redirect.
      try {
        await auth.signOut(scope: SignOutScope.local);
      } catch (_) {
        // Never let a forced logout crash the resume path.
      }
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

    // Initialize router after onboarding status is determined
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
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MultiProvider(
      providers: [
        // Bloc providers
        BlocProvider(create: (context) => getit<AuthBloc>()),
        BlocProvider(create: (context) => getit<MembershipBloc>()),
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
