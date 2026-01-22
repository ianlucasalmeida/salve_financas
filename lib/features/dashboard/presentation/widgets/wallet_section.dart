import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart';
import 'package:salve_financas/features/wallet/data/models/wallet_goal_model.dart';
import 'package:intl/intl.dart';

class WalletSection extends StatefulWidget {
  const WalletSection({super.key});

  @override
  State<WalletSection> createState() => _WalletSectionState();
}

class _WalletSectionState extends State<WalletSection> {
  List<WalletGoalModel> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await isar.walletGoalModels.where().findAll();
    setState(() => _goals = goals);
  }

  // --- FORMULÁRIO PRÉ-SETADO (Modal) ---
  void _showCreateGoalForm() {
    final titleCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
          left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nova Caixinha / Meta", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Input Nome
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Nome do Objetivo (Ex: Viagem)",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),

            // Input Valor
            TextField(
              controller: valueCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Valor da Meta (R\$)",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                onPressed: () async {
                  if (titleCtrl.text.isEmpty || valueCtrl.text.isEmpty) return;

                  final newVal = double.tryParse(valueCtrl.text.replaceAll(',', '.')) ?? 0;
                  
                  final newGoal = WalletGoalModel()
                    ..title = titleCtrl.text
                    ..targetAmount = newVal
                    ..currentAmount = 0 // Começa com 0
                    ..deadline = selectedDate
                    ..categoryIcon = "💰"; // Padrão por enquanto

                  await isar.writeTxn(() async {
                    await isar.walletGoalModels.put(newGoal);
                  });

                  Navigator.pop(context);
                  _loadGoals(); // Recarrega a lista
                },
                child: const Text("CRIAR PROJETO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Função para simular depósito na caixinha ---
  Future<void> _addMoneyToGoal(WalletGoalModel goal) async {
    // Aqui você pode abrir outro modal para perguntar quanto quer depositar
    // Para simplificar, vou adicionar 10% da meta a cada clique como exemplo
    await isar.writeTxn(() async {
      goal.currentAmount += (goal.targetAmount * 0.10);
      if (goal.currentAmount > goal.targetAmount) goal.currentAmount = goal.targetAmount;
      await isar.walletGoalModels.put(goal);
    });
    _loadGoals();
  }

  Future<void> _deleteGoal(int id) async {
    await isar.writeTxn(() async {
      await isar.walletGoalModels.delete(id);
    });
    _loadGoals();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("MINHA CARTEIRA", style: TextStyle(fontFamily: 'monospace', color: Colors.white54, letterSpacing: 1.2)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
              onPressed: _showCreateGoalForm,
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_goals.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(child: Text("Nenhuma meta criada.\nToque no + para começar.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white38))),
          )
        else
          SizedBox(
            height: 180, // Altura do carrossel de cards
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0.0;
                
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.greenAccent.withOpacity(0.1), const Color(0xFF1A1A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.savings, color: Colors.greenAccent),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                            onPressed: () => _deleteGoal(goal.id),
                          )
                        ],
                      ),
                      Text(goal.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Atual: R\$ ${goal.currentAmount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text("Meta: R\$ ${goal.targetAmount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.black,
                        color: Colors.greenAccent,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _addMoneyToGoal(goal),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.greenAccent),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 30)
                          ),
                          child: const Text("DEPOSITAR", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}