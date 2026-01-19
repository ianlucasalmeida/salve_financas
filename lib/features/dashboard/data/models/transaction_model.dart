import 'package:isar/isar.dart';

part 'transaction_model.g.dart';

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  @Index()
  late int userId; // Vinculo com o dono da conta

  late String title;
  late double value;
  late DateTime date;
  late String category;
  late String type; // 'income' ou 'expense'
  
  String? rawText; // Conteúdo original da nota (URL ou texto)
}