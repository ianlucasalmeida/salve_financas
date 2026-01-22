import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Imports de Configuração Core
import 'package:salve_financas/core/router/app_router.dart';
import 'package:salve_financas/core/theme/app_theme.dart';

// Imports de Modelos
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';
import 'package:salve_financas/features/goals/data/models/goal_model.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';
import 'package:salve_financas/core/data/models/app_config_model.dart'; 
// --- NOVO IMPORT ---
import 'package:salve_financas/features/concierge/data/models/chat_message_model.dart';

/// Instância global do Isar.
late Isar isar;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dir = await getApplicationDocumentsDirectory();

    isar = await Isar.open(
      [
        TransactionModelSchema, 
        GoalModelSchema, 
        UserModelSchema,
        AppConfigModelSchema,
        ChatMessageModelSchema, // <--- REGISTRADO AQUI
      ],
      directory: dir.path,
      inspector: true, 
    );

    debugPrint("✅ Isar Database carregado em: ${dir.path}");
  } catch (e) {
    debugPrint("❌ Erro fatal no Isar: $e");
  }

  runApp(const SalveFinancasApp());
}

class SalveFinancasApp extends StatelessWidget {
  const SalveFinancasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Salve Finanças',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}