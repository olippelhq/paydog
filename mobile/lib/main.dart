import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: const DogPayApp(),
    ),
  );
}

class DogPayApp extends StatelessWidget {
  const DogPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final router = GoRouter(
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

    return MaterialApp.router(
      title: 'DogPay',
      theme: dogPayTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
