import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salve_financas/features/auth/presentation/screens/splash_screen.dart';
import 'package:salve_financas/features/auth/presentation/screens/login_screen.dart';
import 'package:salve_financas/features/auth/presentation/screens/register_screen.dart';
import 'package:salve_financas/features/home/presentation/screens/home_wrapper_screen.dart';
import 'package:salve_financas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:salve_financas/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:salve_financas/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:salve_financas/features/services/presentation/screens/interest_calculator_screen.dart';
import 'package:salve_financas/features/profile/presentation/screens/profile_screen.dart';
import 'package:salve_financas/features/concierge/presentation/screens/concierge_screen.dart';

class AppRouter {
  // Definido como static final para o main.dart encontrar
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', name: 'register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/concierge', name: 'concierge', builder: (context, state) => const ConciergeScreen()),

      ShellRoute(
        builder: (context, state, child) => HomeWrapperScreen(child: child),
        routes: [
          GoRoute(path: '/dash', name: 'dash', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/transactions', name: 'transactions', builder: (context, state) => const TransactionsScreen()),
          GoRoute(path: '/scanner', name: 'scanner', builder: (context, state) => const ScannerScreen()),
          GoRoute(path: '/calculator', name: 'calculator', builder: (context, state) => const InterestCalculatorScreen()),
          GoRoute(path: '/profile', name: 'profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
  );
}