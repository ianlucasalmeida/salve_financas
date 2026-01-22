import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart';
import 'package:salve_financas/features/concierge/data/models/chat_message_model.dart';

class ChatHistoryService {
  
  /// Salva uma mensagem no banco
  Future<void> saveMessage(String role, String text) async {
    final msg = ChatMessageModel()
      ..role = role
      ..text = text
      ..createdAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.chatMessageModels.put(msg);
    });
  }

  /// Carrega o histórico completo ordenado
  Future<List<ChatMessageModel>> getHistory() async {
    return await isar.chatMessageModels
        .where()
        .sortByCreatedAt() // Do mais antigo para o mais novo
        .findAll();
  }

  /// Limpa o histórico (Botão de Lixeira)
  Future<void> clearHistory() async {
    await isar.writeTxn(() async {
      await isar.chatMessageModels.clear();
    });
  }
}