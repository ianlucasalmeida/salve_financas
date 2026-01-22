import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart';
import 'package:salve_financas/features/wallet/data/models/wallet_goal_model.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart'; // ✅ Importante para filtrar por usuário
import 'dart:math';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  List<WalletGoalModel> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  /// ✅ Carrega apenas as metas do usuário logado
  Future<void> _loadGoals() async {
    final user = await isar.userModels.filter().isSessionActiveEqualTo(true).findFirst();
    
    if (user != null) {
      final goals = await isar.walletGoalModels
          .filter()
          .userIdEqualTo(user.id) // Filtro de isolamento
          .findAll();
          
      if (mounted) setState(() => _goals = goals);
    }
  }

  /// Parser seguro para moeda
  double _parseCurrency(String text) {
    String clean = text.replaceAll(RegExp(r'[R$\s]'), '');
    if (clean.contains(',')) {
      clean = clean.replaceAll('.', ''); 
      clean = clean.replaceAll(',', '.'); 
    }
    return double.tryParse(clean) ?? 0.0;
  }

  // --- LÓGICA DE DEPÓSITO ---
  Future<void> _processDeposit(WalletGoalModel goal, double amount) async {
    if (amount <= 0) return;

    await isar.writeTxn(() async {
      goal.currentAmount += amount;
      if (goal.currentAmount > goal.targetAmount) goal.currentAmount = goal.targetAmount;
      await isar.walletGoalModels.put(goal);
    });
    
    _loadGoals(); 
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("💰 Adicionado R\$ ${amount.toStringAsFixed(2)}!"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ));
    }
  }

  // --- MODAL DE APORTES ---
  void _showDepositModal(WalletGoalModel goal) {
    final customValueCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, 
            left: 20, right: 20, top: 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Aportar em: ${goal.title}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              const Text("Escolha um valor rápido ou digite outro.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [50, 100, 200].map((val) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A2A2A),
                          foregroundColor: Colors.greenAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _processDeposit(goal, val.toDouble()),
                        child: Text("R\$ $val"),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              
              TextField(
                controller: customValueCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.add, color: Colors.greenAccent),
                  labelText: "Outro Valor (Manual)",
                  labelStyle: const TextStyle(color: Colors.white54),
                  hintText: "0,00",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                    onPressed: () {
                      final val = _parseCurrency(customValueCtrl.text);
                      if (val > 0) {
                        _processDeposit(goal, val);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Digite um valor válido.")));
                      }
                    },
                  ),
                ),
                onSubmitted: (val) {
                  final amount = _parseCurrency(val);
                  if (amount > 0) _processDeposit(goal, amount);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // --- MODAL DE CRIAÇÃO (CORRIGIDO) ---
  void _showCreateGoalForm() {
    final titleCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 365));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
          left: 24, right: 24, top: 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nova Caixinha 📦", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Nome do Objetivo",
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Meta Total (R\$)",
                hintText: "0,00",
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  if (titleCtrl.text.isEmpty || valueCtrl.text.isEmpty) return;
                  
                  try {
                    // 1. ✅ Busca usuário logado
                    final user = await isar.userModels.filter().isSessionActiveEqualTo(true).findFirst();
                    
                    if (user != null) {
                      final targetVal = _parseCurrency(valueCtrl.text);
                      
                      final newGoal = WalletGoalModel()
                        ..title = titleCtrl.text
                        ..targetAmount = targetVal
                        ..currentAmount = 0
                        ..deadline = selectedDate
                        ..categoryIcon = "💰"
                        ..userId = user.id; // ✅ Atribui o ID (Correção do erro)

                      await isar.writeTxn(() async => await isar.walletGoalModels.put(newGoal));

                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadGoals();
                      }
                    } else {
                      // Caso extremo onde a sessão caiu
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sessão inválida. Faça login novamente.")));
                    }
                  } catch (e) {
                    debugPrint("Erro: $e");
                  }
                },
                child: const Text("CRIAR CAIXINHA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SIMULADOR DE INVESTIMENTO ---
  void _showSimulation(WalletGoalModel goal) {
    double falta = goal.targetAmount - goal.currentAmount;
    if (falta <= 0) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        double taxaMensal = 0.008; 
        int mesesPadrao = 12;
        double aporteNecessario = (falta * taxaMensal) / (pow(1 + taxaMensal, mesesPadrao) - 1);

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_graph, color: Colors.orangeAccent),
                  const SizedBox(width: 10),
                  const Text("Planejador de Aporte", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Text("Para atingir a meta em 12 meses investindo em CDB (100% CDI):", style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Aporte Mensal:", style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text("R\$ ${aporteNecessario.toStringAsFixed(2)}", style: const TextStyle(color: Colors.orangeAccent, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteGoal(int id) async {
    await isar.writeTxn(() async => await isar.walletGoalModels.delete(id));
    _loadGoals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("MINHA CARTEIRA", style: TextStyle(fontFamily: 'monospace', fontSize: 16, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGoalForm,
        backgroundColor: Colors.greenAccent,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("NOVA META", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _goals.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.savings_outlined, size: 80, color: Colors.grey[800]),
                const SizedBox(height: 16),
                const Text("Nenhuma caixinha criada.", style: TextStyle(color: Colors.white54, fontSize: 18)),
                const SizedBox(height: 8),
                const Text("Toque em 'Nova Meta' para começar.", style: TextStyle(color: Colors.white24)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _goals.length,
            itemBuilder: (context, index) {
              final goal = _goals[index];
              final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0.0;
              final percent = (progress * 100).toInt();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.flag, color: Colors.greenAccent),
                      ),
                      title: Text(goal.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text("Meta: R\$ ${goal.targetAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteGoal(goal.id),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("R\$ ${goal.currentAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              Text("$percent%", style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: Colors.black,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // --- BOTÕES DE AÇÃO ---
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _showSimulation(goal),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20))),
                              child: const Center(child: Text("PLANEJAR", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 48, color: Colors.white10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showDepositModal(goal),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: const BoxDecoration(color: Color(0xFF222222), borderRadius: BorderRadius.only(bottomRight: Radius.circular(20))),
                              child: const Center(child: Text("+ APORTE", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
    );
  }
}