import 'package:dio/dio.dart';
import 'package:salve_financas/main.dart';
import '../../features/dashboard/data/models/transaction_model.dart';

class SyncService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'SUA_API_AQUI'));

  Future<void> syncNote(TransactionModel tx) async {
    try {
      final response = await _dio.post('/scrape', data: {'url': tx.rawText});
      
      if (response.statusCode == 200) {
        final List itemsData = response.data['items'];
        
        await isar.writeTxn(() async {
          for (var item in itemsData) {
            final newItem = NoteItemModel()
              ..name = item['nome']
              ..quantity = item['qtd']
              ..unitValue = item['vUnit']
              ..totalValue = item['vTotal'];
            
            await isar.noteItemModels.put(newItem);
            tx.items.add(newItem);
          }
          tx.isSynced = true;
          await isar.transactionModels.put(tx);
          await tx.items.save();
        });
      }
    } catch (e) {
      print("API Offline ou Erro: Mantendo localmente. $e");
    }
  }
}