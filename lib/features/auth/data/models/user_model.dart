import 'package:isar/isar.dart';

// O Isar usará este arquivo gerado para o banco de dados local
part 'user_model.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;

  /// Nome completo para exibição no Dashboard e Perfil
  late String name;

  /// E-mail único para login e isolamento de dados
  @Index(unique: true, replace: true)
  late String email;

  /// Senha para autenticação local segura
  late String password;

  /// Moeda preferida ('BTC', 'USD', 'BRL') que dita os gráficos da Dash
  late String preferredCurrency;

  /// Caminho local da foto de perfil (Galeria ou Câmera)
  String? profilePicPath;

  /// Meta de economia mensal: Usada como base para o Econômetro (Design Fiat)
  /// Se o usuário gasta menos do que ganha em relação a esta meta, o ponteiro fica no verde.
  double? monthlySavingsGoal;

  /// Metadados de Auditoria
  DateTime createdAt = DateTime.now();
  
  /// Último acesso para controle de sessão da IA
  DateTime? lastLogin;
}