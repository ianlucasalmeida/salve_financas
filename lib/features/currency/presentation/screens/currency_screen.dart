import 'package:flutter/material.dart';
import '../../domain/services/currency_service.dart';

class CurrencyScreen extends StatelessWidget {
  const CurrencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CurrencyService();

    return Scaffold(
      appBar: AppBar(title: const Text('Cotações de Mercado')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: service.getLiveQuotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }

          final quotes = snapshot.data!;
          return ListView.builder(
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              final q = quotes[index];
              final isUp = double.parse(q['pct']) > 0;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(q['code'][0])),
                  title: Text(q['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Variação: ${q['pct']}%'),
                  trailing: Text('R\$ ${double.parse(q['value']).toStringAsFixed(2)}',
                      style: TextStyle(color: isUp ? Colors.green : Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}