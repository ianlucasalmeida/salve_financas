import 'package:isar/isar.dart';

part 'transaction_model.g.dart';

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  @Index()
  late int userId;

  late String title;
  late double value;
  late DateTime date;
  late String category;
  late String type;
  
  String? rawText; // URL

  // Lista Embutida
  List<TransactionItem>? items; 
}

@embedded
class TransactionItem {
  String? name;
  double? quantity;
  double? unitPrice;
  double? totalPrice;
}