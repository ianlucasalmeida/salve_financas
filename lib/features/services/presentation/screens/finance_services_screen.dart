import 'package:flutter/material.dart';

class FinanceServicesScreen extends StatelessWidget {
  const FinanceServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Serviços Financeiros')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _serviceCard(context, "Juros Compostos", Icons.trending_up),
          _serviceCard(context, "Conversor Moedas", Icons.currency_exchange),
          _serviceCard(context, "Simulador IR", Icons.Description),
        ],
      ),
    );
  }

  Widget _serviceCard(BuildContext context, String title, IconData icon) {
    return Card(
      child: InkWell(
        onTap: () => _openCalculator(context, title),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, size: 40), Text(title)],
        ),
      ),
    );
  }

  void _openCalculator(BuildContext context, String title) {
    // Abre modal para input de parâmetros (Capital, Taxa, Tempo)
  }
}