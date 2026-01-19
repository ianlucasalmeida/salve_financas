import 'package:flutter/material.dart';
import 'dart:math';

class InterestCalculatorScreen extends StatefulWidget {
  const InterestCalculatorScreen({super.key});

  @override
  State<InterestCalculatorScreen> createState() => _InterestCalculatorScreenState();
}

class _InterestCalculatorScreenState extends State<InterestCalculatorScreen> {
  final _val = TextEditingController();
  final _tax = TextEditingController();
  final _parc = TextEditingController();
  double _total = 0;

  void _calcular() {
    double p = double.tryParse(_val.text) ?? 0;
    double i = (double.tryParse(_tax.text) ?? 0) / 100;
    int n = int.tryParse(_parc.text) ?? 1;
    // Fórmula M = P * (1 + i)^n
    setState(() => _total = p * pow((1 + i), n));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora de Juros')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _val, decoration: const InputDecoration(labelText: 'Valor Principal (R\$)'), keyboardType: TextInputType.number),
            TextField(controller: _tax, decoration: const InputDecoration(labelText: 'Taxa Mensal (%)'), keyboardType: TextInputType.number),
            TextField(controller: _parc, decoration: const InputDecoration(labelText: 'Parcelas (Meses)'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _calcular, child: const Text('Simular Custo Real')),
            if (_total > 0) ...[
              const SizedBox(height: 30),
              Text('Total final: R\$ ${_total.toStringAsFixed(2)}', 
                   style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
              Text('Custo do juros: R\$ ${(_total - double.parse(_val.text)).toStringAsFixed(2)}'),
            ]
          ],
        ),
      ),
    );
  }
}