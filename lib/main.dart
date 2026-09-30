import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ufg/core/constants/app_colors.dart';
import 'package:ufg/core/constants/app_routes.dart';
import 'package:ufg/core/notifications/fcm_notification_service.dart';
import 'package:ufg/core/notifications/notification_navigation_service.dart';
import 'package:ufg/core/routes/app_router.dart';
import 'package:ufg/core/theme/app_theme.dart';
import 'package:ufg/core/utils/app_state_notifier.dart';
import 'package:ufg/core/utils/session_expiry_policy.dart';
import 'package:ufg/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ufg/features/loans/presentation/bloc/loan_bloc.dart';
import 'package:ufg/features/membership/presentation/bloc/membership_bloc.dart';
import 'package:ufg/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:ufg/features/notifications/presentation/bloc/notification_event.dart';
import 'package:ufg/features/savings/presentation/bloc/savings_bloc.dart';
import 'package:ufg/injection_container.dart';
import 'core/config/supabase_config.dart';
import 'core/messaging/root_scaffold_messenger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/env/.env");
  await SupabaseConfig.init();
  initDependency(); // initializing getit for dependency injection

  // Push is optional infrastructure: a Firebase/FCM failure must never stop
  // the app from starting. The in-app inbox works without it.
  try {
    await getit<FcmNotificationService>().initialize();

    // The auth state stream can emit `initialSession` before our listener
    // attaches on cold start, so register explicitly when a session was
    // already restored. Fresh logins are handled by the auth listener below.
    if (Supabase.instance.client.auth.currentSession != null) {
      unawaited(getit<FcmNotificationService>().syncDeviceRegistration());
    }
  } catch (e) {
    if (kDebugMode) {
      developer.log('FCM initialization skipped: $e');
    }
  }

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
        _syncNotificationSession(data.event);
      },
      onError: (Object error) {
        if (kDebugMode) {
          developer.log('Auth state stream error (ignored): $error');
        }
      },
    );
  }

  /// Registers the FCM device once a session exists and clears local
  /// notification state when the session ends.
  ///
  /// Device deactivation on logout happens in `AuthBloc.onBeforeSignOut`,
  /// while the JWT is still valid.
  void _syncNotificationSession(AuthChangeEvent event) {
    switch (event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.initialSession:
        unawaited(getit<FcmNotificationService>().syncDeviceRegistration());
        break;
      case AuthChangeEvent.signedOut:
        getit<NotificationBloc>().add(const ResetNotificationsRequested());
        break;
      default:
        break;
    }
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
        getit<NotificationBloc>().add(
          const LoadUnreadNotificationCountRequested(),
        );
        // Recovers a failed device registration (returns immediately when the
        // device is already registered).
        unawaited(getit<FcmNotificationService>().syncDeviceRegistration());
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

    // A cold-start notification tap is buffered by the navigation service until
    // the router exists, so attach immediately after creation.
    NotificationNavigationService.instance.attachRouter(_router);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget loadingScreen() {
    return Scaffold(
      body: Center(child: SpinKitWave(color: ColorConstants.accent, size: 50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        home: Scaffold(body: Center(child: loadingScreen())),
      );
    }
    return MultiProvider(
      providers: [
        BlocProvider(create: (context) => getit<AuthBloc>()),
        BlocProvider(create: (context) => getit<MembershipBloc>()),
        BlocProvider(create: (context) => getit<SavingsBloc>()),
        BlocProvider(create: (context) => getit<LoanBloc>()),
        BlocProvider(create: (context) => getit<NotificationBloc>()),
        ChangeNotifierProvider(create: (context) => getit<AppStateNotifier>()),
      ],
      child: Consumer<AppStateNotifier>(
        builder: (context, appState, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Unity Finance Group',
            routerConfig: _router,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            theme: ThemeConfig.lightTheme,
            darkTheme: ThemeConfig.darkTheme,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          );
        },
      ),
    );
  }
}
