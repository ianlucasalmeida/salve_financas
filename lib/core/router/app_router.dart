import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart'; 
import 'package:salve_financas/features/auth/data/models/user_model.dart';

// Telas de Autenticação e Core
import 'package:salve_financas/features/auth/presentation/screens/splash_screen.dart';
import 'package:salve_financas/features/auth/presentation/screens/login_screen.dart';
import 'package:salve_financas/features/auth/presentation/screens/register_screen.dart';
import 'package:salve_financas/features/home/presentation/screens/home_wrapper_screen.dart';

// Telas Funcionais
import 'package:salve_financas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:salve_financas/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:salve_financas/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:salve_financas/features/calculator/calculator_screen.dart';
import 'package:salve_financas/features/profile/presentation/screens/profile_screen.dart';
// Import da nova tela de Configurações
import 'package:salve_financas/features/profile/presentation/screens/settings_screen.dart'; 
import 'package:salve_financas/features/concierge/presentation/screens/concierge_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    
    // Auth Guard
    redirect: (context, state) async {
      final user = await isar.userModels.filter().idGreaterThan(0).findFirst();
      final isLoggedIn = user != null;
      
      final isAuthRoute = state.uri.toString() == '/login' || state.uri.toString() == '/register';
      final isSplash = state.uri.toString() == '/';

      if (!isLoggedIn && !isAuthRoute && !isSplash) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dash';

      return null;
    },

    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', name: 'register', builder: (context, state) => const RegisterScreen()),
      
      // Rotas do Concierge
      GoRoute(path: '/concierge', name: 'concierge', builder: (context, state) => const ConciergeScreen()),
      
      // ROTA DE CONFIGURAÇÕES (Adicionada)
      GoRoute(
        path: '/settings', 
        name: 'settings', 
        builder: (context, state) => const SettingsScreen()
      ),

      // Shell Route (Barra de Navegação Inferior)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeWrapperScreen(child: child),
        routes: [
          GoRoute(path: '/dash', name: 'dash', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/transactions', name: 'transactions', builder: (context, state) => const TransactionsScreen()),
          GoRoute(path: '/scanner', name: 'scanner', builder: (context, state) => const ScannerScreen()),
          GoRoute(path: '/calculator', name: 'calculator', builder: (context, state) => const CalculatorScreen()),
          GoRoute(path: '/profile', name: 'profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
  );
}