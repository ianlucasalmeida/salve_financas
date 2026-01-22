import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart';
import 'package:salve_financas/features/wallet/data/models/wallet_goal_model.dart';

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

  Future<void> _loadGoals() async {
    final goals = await isar.walletGoalModels.where().findAll();
    setState(() => _goals = goals);
  }

  // --- MODAL DE CRIAÇÃO ---
  void _showCreateGoalForm() {
    final titleCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    
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
            const SizedBox(height: 8),
            const Text("Defina um objetivo para começar a guardar.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Nome (Ex: Viagem, Carro)",
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: valueCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Meta (R\$)",
                prefixText: "R\$ ",
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

                  final newVal = double.tryParse(valueCtrl.text.replaceAll(',', '.')) ?? 0;
                  
                  final newGoal = WalletGoalModel()
                    ..title = titleCtrl.text
                    ..targetAmount = newVal
                    ..currentAmount = 0
                    ..deadline = DateTime.now().add(const Duration(days: 365)) // Padrão 1 ano
                    ..categoryIcon = "💰";

                  await isar.writeTxn(() async {
                    await isar.walletGoalModels.put(newGoal);
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    _loadGoals();
                  }
                },
                child: const Text("CRIAR CAIXINHA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deposit(WalletGoalModel goal) async {
    // Simulação de depósito rápido (10% ou R$ 100)
    await isar.writeTxn(() async {
      goal.currentAmount += 100; // Adiciona 100 reais
      if (goal.currentAmount > goal.targetAmount) goal.currentAmount = goal.targetAmount;
      await isar.walletGoalModels.put(goal);
    });
    _loadGoals();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("💰 R\$ 100,00 guardados!")));
  }

  Future<void> _deleteGoal(int id) async {
    await isar.writeTxn(() async {
      await isar.walletGoalModels.delete(id);
    });
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
                const Text("Sua carteira está vazia", style: TextStyle(color: Colors.white54, fontSize: 18)),
                const Text("Crie caixinhas para organizar seus sonhos.", style: TextStyle(color: Colors.white24)),
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
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flag, color: Colors.greenAccent),
                      ),
                      title: Text(goal.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("Faltam R\$ ${(goal.targetAmount - goal.currentAmount).toStringAsFixed(2)}", style: const TextStyle(color: Colors.grey)),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onPressed: () => _deleteGoal(goal.id),
                      ),
                    ),
                    
                    // Barra de Progresso
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("R\$ ${goal.currentAmount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              Text("$percent%", style: const TextStyle(color: Colors.white)),
                              Text("R\$ ${goal.targetAmount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              backgroundColor: Colors.black,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Botão Depositar
                    InkWell(
                      onTap: () => _deposit(goal),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: const BoxDecoration(
                          color: Color(0xFF222222),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        ),
                        child: const Center(
                          child: Text("+ GUARDAR R\$ 100", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
    );
  }
}