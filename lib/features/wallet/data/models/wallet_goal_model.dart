import 'package:isar/isar.dart';

part 'wallet_goal_model.g.dart';

@collection
class WalletGoalModel {
  Id id = Isar.autoIncrement;

  late String title; // Ex: Viagem, Carro, Reserva
  late double targetAmount; // Meta: R$ 5000
  late double currentAmount; // Atual: R$ 1000
  late DateTime deadline; // Data limite
  late String categoryIcon; // Ex: ✈️, 🚗, 💰
}