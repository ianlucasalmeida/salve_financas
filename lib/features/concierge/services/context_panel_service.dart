import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart';
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';

class ContextPanelService {
  Map<String, dynamic>? _rules;

  /// Carrega as regras do JSON na memória
  Future<void> _loadRules() async {
    if (_rules != null) return;
    final jsonString = await rootBundle.loadString('assets/context_rules.json');
    _rules = jsonDecode(jsonString);
  }

  /// Gera o "Prompt de Contexto" otimizado para a LLM
  Future<String> buildFinancialPersona() async {
    await _loadRules();
    
    // 1. Coleta Dados Reais (Isar)
    final now = DateTime.now();
    final startYear = DateTime(now.year, 1, 1);
    
    final txs = await isar.transactionModels
        .filter()
        .dateGreaterThan(startYear) // Pega o ano todo para análise de IR
        .findAll();

    double totalIncome = 0;
    double totalExpense = 0;
    
    for (var t in txs) {
      if (t.type == 'income') totalIncome += t.value;
      else totalExpense += t.value;
    }

    double saldo = totalIncome - totalExpense;
    double taxaPoupanca = totalIncome > 0 ? (saldo / totalIncome) : 0;

    // 2. Aplica a Lógica Rígida (Dart processa, IA fala)
    Map<String, dynamic> healthStatus;
    
    if (saldo < 0) {
      healthStatus = _rules!['financial_health_levels']['critical'];
    } else if (taxaPoupanca < 0.20) { // Menos de 20% de poupança
      healthStatus = _rules!['financial_health_levels']['warning'];
    } else {
      healthStatus = _rules!['financial_health_levels']['healthy'];
    }

    // 3. Verifica Regras Fiscais (Ex: IRPF)
    String taxAlert = "";
    if (totalIncome > 28559) { // Valor hipotético do JSON
      taxAlert = "ALERTA FISCAL: O usuário já superou a faixa de isenção do IR anual. Lembre-o de organizar os comprovantes.";
    }

    // 4. Monta o PROMPT FINAL OTIMIZADO
    // A IA recebe apenas o resultado da análise, economizando tokens e processamento.
    return """
    [DIRETRIZES DE SEGURANÇA]
    ${_rules!['meta']['disclaimer']}

    [PAINEL DE SITUAÇÃO DO USUÁRIO]
    - Status Atual: ${healthStatus['label']}
    - Diretriz de Atuação: ${healthStatus['advice']}
    - $taxAlert

    [DADOS REAIS (Referência)]
    - Receita Ano: R\$ ${totalIncome.toStringAsFixed(2)}
    - Despesa Ano: R\$ ${totalExpense.toStringAsFixed(2)}
    - Saldo Líquido: R\$ ${saldo.toStringAsFixed(2)}
    """;
  }
}