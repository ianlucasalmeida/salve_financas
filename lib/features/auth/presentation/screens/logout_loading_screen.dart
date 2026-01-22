import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart';
import 'package:salve_financas/core/presentation/widgets/app_logo.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';

class LogoutLoadingScreen extends StatefulWidget {
  const LogoutLoadingScreen({super.key});

  @override
  State<LogoutLoadingScreen> createState() => _LogoutLoadingScreenState();
}

class _LogoutLoadingScreenState extends State<LogoutLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _performSecureLogout();
  }

  Future<void> _performSecureLogout() async {
    // Simulamos um pequeno delay para a animação e segurança (1.5s)
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      // Busca o usuário ativo e desativa a sessão
      final user = await isar.userModels.filter().isSessionActiveEqualTo(true).findFirst();
      
      if (user != null) {
        await isar.writeTxn(() async {
          user.isSessionActive = false;
          await isar.userModels.put(user);
        });
      }
    } catch (e) {
      debugPrint("Erro ao encerrar sessão: $e");
    }

    if (mounted) {
      // Navega para o login limpando o histórico de rotas
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(size: 100, useHero: true),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.redAccent,
              strokeWidth: 2,
            ),
            const SizedBox(height: 24),
            Text(
              "ENCERRANDO SESSÃO",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Protegendo seus dados locais...",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}