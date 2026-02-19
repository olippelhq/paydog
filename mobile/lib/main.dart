import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:datadog_session_replay/datadog_session_replay.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configuration = DatadogConfiguration(
    clientToken: 'pubba291f1c5cf3ecc478c713d260fbc53b',
    env: 'sandbox',
    site: DatadogSite.us1,
    nativeCrashReportEnabled: true,
    loggingConfiguration: DatadogLoggingConfiguration(),
    rumConfiguration: DatadogRumConfiguration(
      applicationId: '6f0f8457-e787-494e-bc12-eefba936c769',
      detectLongTasks: true,
    ),
  )..enableSessionReplay(
    DatadogSessionReplayConfiguration(
      replaySampleRate: 100.0,
      textAndInputPrivacyLevel: TextAndInputPrivacyLevel.maskSensitiveInputs,
      imagePrivacyLevel: ImagePrivacyLevel.maskNonAssetsOnly,
      touchPrivacyLevel: TouchPrivacyLevel.show,
    ),
  );

  await DatadogSdk.runApp(configuration, TrackingConsent.granted, () async {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
          ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ],
        child: const DogPayApp(),
      ),
    );
  });
}

class DogPayApp extends StatefulWidget {
  const DogPayApp({super.key});

  @override
  State<DogPayApp> createState() => _DogPayAppState();
}

class _DogPayAppState extends State<DogPayApp> {
  var _captureKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final router = GoRouter(
      observers: [DatadogNavigationObserver(datadogSdk: DatadogSdk.instance)],
      initialLocation: '/login',
      redirect: (context, state) {
        if (authProvider.status == AuthStatus.unknown) return null;
        final isAuth  = authProvider.status == AuthStatus.authenticated;
        final isGuest = state.matchedLocation == '/login' ||
                        state.matchedLocation == '/register';
        if (!isAuth && !isGuest)  return '/login';
        if (isAuth  && isGuest)   return '/dashboard';
        return null;
      },
      refreshListenable: authProvider,
      routes: [
        GoRoute(path: '/login',     builder: (context, _) => const LoginScreen()),
        GoRoute(path: '/register',  builder: (context, _) => const RegisterScreen()),
        GoRoute(path: '/dashboard', builder: (context, _) => const DashboardScreen()),
      ],
    );

    return SessionReplayCapture(
      key: _captureKey,
      rum: DatadogSdk.instance.rum!,
      sessionReplay: DatadogSessionReplay.instance!,
      child: MaterialApp.router(
        title: 'DogPay',
        theme: dogPayTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
