import 'package:isar/isar.dart';
import '../../../../main.dart'; // Importa a instância global do isar
import '../models/transaction_model.dart';

class DashboardRepository {
  // Buscar todas as transações ordenadas por data (mais recente primeiro)
  Future<List<TransactionModel>> getAllTransactions() async {
    return await isar.transactionModels.where().sortByDateDesc().findAll();
  }

  // Adicionar uma nova transação
  Future<void> saveTransaction(TransactionModel transaction) async {
    await isar.writeTxn(() async {
      await isar.transactionModels.put(transaction);
    });
  }

  // Stream para escutar mudanças no banco em tempo real
  Stream<List<TransactionModel>> listenTransactions() {
    return isar.transactionModels.where().sortByDateDesc().watch(fireImmediately: true);
  }
}