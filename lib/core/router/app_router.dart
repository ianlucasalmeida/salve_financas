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
import 'package:salve_financas/features/profile/presentation/screens/profile_screen.dart';
import 'package:salve_financas/features/profile/presentation/screens/settings_screen.dart'; 
import 'package:salve_financas/features/concierge/presentation/screens/concierge_screen.dart';

// ✅ IMPORT DA NOVA TELA (Substituindo a Calculadora)
import 'package:salve_financas/features/wallet/presentation/screens/wallet_screen.dart';

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
      
      // Rotas Auxiliares
      GoRoute(path: '/concierge', name: 'concierge', builder: (context, state) => const ConciergeScreen()),
      GoRoute(path: '/settings', name: 'settings', builder: (context, state) => const SettingsScreen()),

      // BARRA DE NAVEGAÇÃO (Shell Route)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeWrapperScreen(child: child),
        routes: [
          // 1. Dashboard
          GoRoute(path: '/dash', name: 'dash', builder: (context, state) => const DashboardScreen()),
          
          // 2. Transações
          GoRoute(path: '/transactions', name: 'transactions', builder: (context, state) => const TransactionsScreen()),
          
          // 3. Scanner
          GoRoute(path: '/scanner', name: 'scanner', builder: (context, state) => const ScannerScreen()),
          
          // 4. CARTEIRA (Antiga Calculadora) - ✅ MUDANÇA AQUI
          GoRoute(
            path: '/wallet', 
            name: 'wallet', 
            builder: (context, state) => const WalletScreen()
          ),
          
          // 5. Perfil
          GoRoute(path: '/profile', name: 'profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
  );
}