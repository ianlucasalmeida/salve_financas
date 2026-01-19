import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Imports de Configuração Core
import 'package:salve_financas/core/router/app_router.dart';
import 'package:salve_financas/core/theme/app_theme.dart';

// Imports de Modelos (Essenciais para o Isar)
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';
import 'package:salve_financas/features/goals/data/models/goal_model.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';

/// Instância global do Isar. 
/// O uso de 'late' exige que a inicialização ocorra no main antes de qualquer uso.
late Isar isar;

void main() async {
  // 1. Garante que os serviços nativos (binding) estejam prontos antes do Isar
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 2. Localiza o diretório de documentos do sistema (Fedora, Android ou iOS)
    final dir = await getApplicationDocumentsDirectory();
    
    // 3. Abre o Banco Isar com todos os esquemas de dados do projeto.
    // O UserModelSchema é vital para o fluxo de Login/Cadastro funcionar.
    isar = await Isar.open(
      [
        TransactionModelSchema, 
        GoalModelSchema, 
        UserModelSchema,
      ],
      directory: dir.path,
    );
    
    debugPrint("✅ Isar Database carregado com sucesso em: ${dir.path}");
  } catch (e) {
    debugPrint("❌ Erro fatal ao inicializar o banco de dados: $e");
    // Em caso de erro no Isar, o app não deve prosseguir para evitar crashes de null pointer
  }

  // 4. Dispara a aplicação
  runApp(const SalveFinancasApp());
}

class SalveFinancasApp extends StatelessWidget {
  const SalveFinancasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Salve Finanças',
      debugShowCheckedModeBanner: false,
      
      // Aplica o tema Dark oficial do Salve Finanças
      theme: AppTheme.darkTheme,
      
      // Configuração do GoRouter. 
      // Certifique-se de que AppRouter.router esteja definido como 'static final'.
      routerConfig: AppRouter.router,
    );
  }
}