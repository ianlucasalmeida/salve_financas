import 'package:isar/isar.dart';

part 'app_config_model.g.dart';

@collection
class AppConfigModel {
  Id id = Isar.autoIncrement;

  // Se true = Usa 1.5GB RAM (Contexto 4096). Se false = Usa 800MB (Contexto 1024)
  bool highPerformanceMode = true; 
  
  // Caminho do modelo baixado (opcional, mas bom pra cache)
  String? aiModelPath;
}