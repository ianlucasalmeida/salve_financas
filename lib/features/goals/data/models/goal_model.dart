import 'package:isar/isar.dart';

part 'goal_model.g.dart';

@collection
class GoalModel {
  Id id = Isar.autoIncrement;
  late String title;
  late double targetAmount;
  late double currentAmount;
  late DateTime deadline;
  
  // Define se a IA deve priorizar esta meta no Concierge
  bool isPriority = false;

  // Categoria para a IA saber o "porquê" da meta (Ex: Aposentadoria, Carro, Viagem)
  late String category;
}