import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart'; // Acesso ao Isar
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';
import '../../models/investment_plan.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // Controladores iniciam vazios (sem dados mocados)
  final _initial = TextEditingController();
  final _monthly = TextEditingController();
  final _rate = TextEditingController();
  final _months = TextEditingController();
  
  double _result = 0;
  String _selectedMode = 'Compostos'; // Opção padrão

  @override
  void initState() {
    super.initState();
    _fetchRealBalance(); // Busca saldo real do usuário
  }

  /// Busca o saldo real no Isar para preencher o campo inicial (Opcional)
  Future<void> _fetchRealBalance() async {
    try {
      final txs = await isar.transactionModels.where().findAll();
      double balance = txs.fold(0.0, (sum, t) => t.type == 'expense' ? sum - t.value : sum + t.value);
      
      if (mounted && balance > 0) {
        setState(() {
          _initial.text = balance.toStringAsFixed(2);
        });
      }
    } catch (e) {
      // Se der erro ou não tiver saldo, mantém vazio (sem dados falsos)
    }
  }

  void _calculate() {
    // Evita crash se campos estiverem vazios
    if (_rate.text.isEmpty || _months.text.isEmpty) return;

    final double initial = double.tryParse(_initial.text.replaceAll(',', '.')) ?? 0.0;
    final double monthly = double.tryParse(_monthly.text.replaceAll(',', '.')) ?? 0.0;
    final double rate = double.tryParse(_rate.text.replaceAll(',', '.')) ?? 0.0;
    final int months = int.tryParse(_months.text) ?? 0;

    final plan = InvestmentPlan(
      initialAmount: initial,
      monthlyContribution: monthly,
      annualRate: rate,
      periodMonths: months,
    );

    setState(() {
      if (_selectedMode == 'Compostos') {
        _result = plan.calculateCompoundInterest();
      } else {
        _result = plan.calculateSimpleInterest();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text("TERMINAL CALC", 
          style: TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, letterSpacing: 2, fontSize: 14)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 1. Seletor de Modo (Dropdown Técnico)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMode,
                dropdownColor: const Color(0xFF111111),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.greenAccent),
                style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
                isExpanded: true,
                items: ['Compostos', 'Simples'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text("MODO: JUROS ${value.toUpperCase()}"),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedMode = newValue!;
                    _calculate(); // Recalcula ao trocar o modo
                  });
                },
              ),
            ),
          ),

          // 2. Inputs (Design Central)
          _buildInput("CAPITAL INICIAL (R\$)", _initial),
          _buildInput("APORTE MENSAL (R\$)", _monthly),
          
          Row(
            children: [
              Expanded(child: _buildInput("TAXA ANUAL (%)", _rate)),
              const SizedBox(width: 16),
              Expanded(child: _buildInput("MESES", _months)),
            ],
          ),

          const SizedBox(height: 32),

          // 3. Resultado (Destaque)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                const Text("TOTAL ESTIMADO AO FINAL:", 
                  style: TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace', letterSpacing: 1)),
                const SizedBox(height: 8),
                FittedBox(
                  child: Text(
                    "R\$ ${_result.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.greenAccent, 
                      fontSize: 40, 
                      fontWeight: FontWeight.bold, 
                      fontFamily: 'monospace'
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 4. Botão de Ação
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: _calculate,
            child: const Text("SIMULAR AGORA", 
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'monospace')),
          )
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
        onChanged: (_) => _calculate(), // Reativo
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.greenAccent, fontSize: 10),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}