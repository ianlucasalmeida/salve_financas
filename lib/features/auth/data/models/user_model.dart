import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;

  late String name;

  @Index(unique: true, replace: true)
  late String email;

  late String password; // ✅ Padronizado para 'password'

  late String preferredCurrency;

  String? profilePicPath;

  double? monthlySavingsGoal; // Regra de negócio: Meta para o Econômetro

  DateTime createdAt = DateTime.now();
  
  DateTime? lastLogin;

  bool isSessionActive = false; // Controle de Logout/Login
}