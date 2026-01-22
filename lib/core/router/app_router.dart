import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart'; 
import 'package:salve_financas/features/auth/data/models/user_model.dart';

// Telas Core
import 'package:salve_financas/features/auth/presentation/screens/splash_screen.dart';
import 'package:salve_financas/features/auth/presentation/screens/login_screen.dart';
import 'package:salve_financas/features/auth/presentation/screens/register_screen.dart';
import 'package:salve_financas/features/auth/presentation/screens/logout_loading_screen.dart';
import 'package:salve_financas/features/home/presentation/screens/home_wrapper_screen.dart';

// Telas de Funcionalidades
import 'package:salve_financas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:salve_financas/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:salve_financas/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:salve_financas/features/profile/presentation/screens/profile_screen.dart';
import 'package:salve_financas/features/profile/presentation/screens/settings_screen.dart'; 
import 'package:salve_financas/features/concierge/presentation/screens/concierge_screen.dart';
import 'package:salve_financas/features/calculator/calculator_screen.dart';
import 'package:salve_financas/features/wallet/presentation/screens/wallet_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    
    // --- LÓGICA DE REDIRECIONAMENTO (AUTH GUARD) ---
    redirect: (context, state) async {
      // 1. Verifica se existe algum usuário com sessão ativa (logado)
      final loggedUser = await isar.userModels
          .filter()
          .isSessionActiveEqualTo(true)
          .findFirst();
      
      final isLoggedIn = loggedUser != null;
      
      // Identificação das rotas atuais
      final isAuthRoute = state.uri.toString() == '/login' || state.uri.toString() == '/register';
      final isSplash = state.uri.toString() == '/';
      final isLogoutLoading = state.uri.toString() == '/logout-loading';

      // REGRA 1: Se não está logado e tenta acessar rotas internas -> Login
      if (!isLoggedIn && !isAuthRoute && !isSplash && !isLogoutLoading) {
        return '/login';
      }
      
      // REGRA 2: Se já está logado e tenta ir para Login ou Registro -> Dashboard
      if (isLoggedIn && isAuthRoute) {
        return '/dash';
      }

      return null; // Mantém a rota solicitada
    },

    routes: [
      // Rotas de Entrada e Autenticação
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', name: 'register', builder: (context, state) => const RegisterScreen()),
      
      // Tela de transição de Logout
      GoRoute(
        path: '/logout-loading', 
        name: 'logout_loading', 
        builder: (context, state) => const LogoutLoadingScreen()
      ),
      
      // Rotas de Configuração e Utilitários (Fora da barra inferior)
      GoRoute(path: '/concierge', name: 'concierge', builder: (context, state) => const ConciergeScreen()),
      GoRoute(path: '/settings', name: 'settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(
        path: '/calculator', 
        name: 'calculator', 
        builder: (context, state) => const CalculatorScreen()
      ),

      // Estrutura principal com BottomNavigationBar (ShellRoute)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeWrapperScreen(child: child),
        routes: [
          GoRoute(path: '/dash', name: 'dash', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/transactions', name: 'transactions', builder: (context, state) => const TransactionsScreen()),
          GoRoute(path: '/scanner', name: 'scanner', builder: (context, state) => const ScannerScreen()),
          GoRoute(path: '/wallet', name: 'wallet', builder: (context, state) => const WalletScreen()),
          GoRoute(path: '/profile', name: 'profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
  );
}