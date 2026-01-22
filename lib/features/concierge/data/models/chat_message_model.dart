import 'package:isar/isar.dart';

part 'chat_message_model.g.dart'; // O build_runner vai gerar isso

@collection
class ChatMessageModel {
  Id id = Isar.autoIncrement;

  late String role; // 'user' ou 'bot'
  late String text;
  
  @Index()
  late DateTime createdAt;

  // Se a mensagem teve anexo (opcional para futuro)
  String? attachmentType; 
}