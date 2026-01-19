import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart'; // Acesso ao 'isar' global
import 'package:salve_financas/features/auth/data/models/user_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Inicia a animação de Fade-in
    _startAnimation();

    // Executa a verificação de autenticação real
    _checkAuthAndNavigate();
  }

  void _startAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });
  }

  /// Lógica de decisão: Cadastro ou Login?
  Future<void> _checkAuthAndNavigate() async {
    // Aguarda o tempo mínimo da animação para não quebrar a experiência visual
    await Future.delayed(const Duration(seconds: 3));

    try {
      // Verifica no Isar se já existe ao menos um usuário criado
      final userCount = await isar.userModels.count();

      if (mounted) {
        if (userCount == 0) {
          // Se não há usuário, o fluxo obrigatório é o Cadastro
          context.go('/register');
        } else {
          // Se já existe, o usuário deve se autenticar no Login
          context.go('/login');
        }
      }
    } catch (e) {
      debugPrint("Erro ao verificar persistência: $e");
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212), 
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeIn,
          opacity: _opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo oficial com tratamento de erro
              Image.asset(
                'assets/images/salve_logo2.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.account_balance_wallet, 
                    size: 100, 
                    color: theme.primaryColor,
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'SALVE FINANÇAS',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Indicador de progresso em harmonia com o tema
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: theme.primaryColor,
                  strokeWidth: 2,
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                "INTELIGÊNCIA FINANCEIRA",
                style: TextStyle(
                  color: theme.primaryColor.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}