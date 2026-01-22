import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Config e Rotas
import 'package:salve_financas/core/router/app_router.dart';
import 'package:salve_financas/core/theme/app_theme.dart';

// Modelos
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';
import 'package:salve_financas/features/goals/data/models/goal_model.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';
import 'package:salve_financas/core/data/models/app_config_model.dart'; 
import 'package:salve_financas/features/concierge/data/models/chat_message_model.dart';
import 'package:salve_financas/features/wallet/data/models/wallet_goal_model.dart'; // ✅ Importante

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
        ChatMessageModelSchema,
        WalletGoalModelSchema, // ✅ Schema registrado para evitar o crash
      ],
      directory: dir.path,
      inspector: true, 
    );
  } catch (e) {
    debugPrint("❌ Erro no Isar: $e");
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