import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart'; 
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';
import 'package:salve_financas/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:salve_financas/features/currency/domain/services/currency_service.dart';

class DashboardController extends ChangeNotifier {
  final _repository = DashboardRepository();
  final _currencyService = CurrencyService();
  
  Map<String, dynamic> quotes = {};
  String featuredCurrency = 'BTC'; // Propriedade que faltava

  Stream<List<TransactionModel>> get transactionStream => _repository.listenTransactions();

  Future<void> refreshQuotes() async {
    try {
      final data = await _currencyService.getLiveQuotes();
      for (var item in data) {
        quotes['${item['code']}BRL'] = {'bid': item['value']};
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Erro: $e");
    }
  }

  Future<void> addQuickTransaction() async {
    final newTx = TransactionModel()
      ..title = "Transação Rápida"
      ..value = 10.0
      ..date = DateTime.now()
      ..category = "Teste"
      ..type = 'expense';
    
    await isar.writeTxn(() => isar.transactionModels.put(newTx));
  }
}