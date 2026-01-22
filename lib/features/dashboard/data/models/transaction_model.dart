import 'package:isar/isar.dart';

part 'transaction_model.g.dart';

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  @Index()
  late int userId; // Vínculo com o usuário

  late String title;
  late double value;
  late DateTime date;
  late String type; // 'income' ou 'expense'
  late String category;

  // ✅ NOVOS CAMPOS (Essenciais para a IA e o Extrato Detalhado)
  String? paymentMethod; // Ex: 'Crédito', 'Débito', 'PIX'
  int? installments;     // Ex: 1, 10, 12...

  // Campo para armazenar o texto cru do OCR
  String? rawText;

  // Lista de produtos da nota fiscal
  List<TransactionItem>? items;
}

@embedded
class TransactionItem {
  String? name;
  double? quantity;
  double? unitPrice;
  double? totalPrice;
}