import 'package:isar/isar.dart';

part 'wallet_goal_model.g.dart';

@collection
class WalletGoalModel {
  Id id = Isar.autoIncrement;

  late String title; // Ex: Viagem, Carro, Reserva
  
  late double targetAmount; // Meta: R$ 5000
  
  late double currentAmount; // Atual: R$ 1000
  
  late DateTime deadline; // Data limite
  
  late String categoryIcon; // Ex: ✈️, 🚗, 128641

  // ✅ VINCULO COM O USUÁRIO: Essencial para o isolamento de dados
  // Isso permitirá usar o .userIdEqualTo(_user!.id) no gráfico da Dashboard
  @Index()
  late int userId; 
}