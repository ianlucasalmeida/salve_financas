import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart';
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';

class ContextPanelService {
  
  /// Gera o contexto puramente factual para a LLM.
  /// Removemos avisos de segurança para evitar que o Llama entre em modo de recusa.
  Future<String> buildFinancialPersona() async {
    final user = await isar.userModels.where().findFirst();
    if (user == null) return "Sem dados de usuário.";

    // 1. Coleta Totais do Ano (Dados Macro)
    final now = DateTime.now();
    final startYear = DateTime(now.year, 1, 1);
    
    final allTxs = await isar.transactionModels
        .filter()
        .userIdEqualTo(user.id)
        .dateGreaterThan(startYear) 
        .findAll();

    double totalIncome = 0;
    double totalExpense = 0;
    
    for (var t in allTxs) {
      if (t.type == 'income') totalIncome += t.value;
      else totalExpense += t.value;
    }

    double saldo = totalIncome - totalExpense;

    // 2. Coleta HISTÓRICO RECENTE (Últimas 10)
    final recentTxs = await isar.transactionModels
        .filter()
        .userIdEqualTo(user.id)
        .sortByDateDesc()
        .limit(10)
        .findAll();

    StringBuffer historyBuffer = StringBuffer();
    if (recentTxs.isEmpty) {
      historyBuffer.writeln("Nenhuma transação registrada recentemente.");
    } else {
      for (var t in recentTxs) {
        final dateStr = "${t.date.day.toString().padLeft(2,'0')}/${t.date.month.toString().padLeft(2,'0')}";
        final typeSymbol = t.type == 'income' ? '(+)' : '(-)';
        
        // Ex: 21/01 (-) R$ 50.00 - Padaria [Alimentação]
        historyBuffer.writeln("$dateStr $typeSymbol R\$ ${t.value.toStringAsFixed(2)} - ${t.title} [${t.category}]");
      }
    }

    // 3. Monta o PROMPT NEUTRO
    // Apenas dados. A IA decidirá o tom da conversa baseada no System Prompt.
    return """
    [DADOS DO USUÁRIO - ANO CORRENTE]
    - Total Receitas: R\$ ${totalIncome.toStringAsFixed(2)}
    - Total Despesas: R\$ ${totalExpense.toStringAsFixed(2)}
    - Saldo Líquido: R\$ ${saldo.toStringAsFixed(2)}

    [EXTRATO DE TRANSAÇÕES RECENTES]
    ${historyBuffer.toString()}
    """;
  }
}