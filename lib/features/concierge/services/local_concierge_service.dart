import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart'; 
import 'package:salve_financas/core/data/models/app_config_model.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:salve_financas/features/concierge/services/ai_manager_service.dart';
import 'package:salve_financas/features/concierge/services/context_panel_service.dart';

class LocalConciergeService {
  final AiManagerService _aiManager = AiManagerService();
  final ContextPanelService _contextPanel = ContextPanelService();
  final LlamaController _llama = LlamaController();
  
  bool _isModelLoaded = false;

  Future<void> _loadModel() async {
    if (_isModelLoaded) return;

    try {
      final path = await _aiManager.getModelPath();
      
      // Carrega configuração apenas para log, já que vamos usar o padrão da lib por segurança
      final config = await isar.appConfigModels.where().findFirst();
      debugPrint("🧠 Inicializando Motor Neural (Modo Seguro)");

      // CORREÇÃO: Passando apenas o caminho obrigatório.
      // A lib vai gerenciar threads e GPU automaticamente.
      await _llama.loadModel(
        modelPath: path,
      );
      
      _isModelLoaded = true;
    } catch (e) {
      debugPrint("Erro Load Model: $e");
      throw Exception("Falha ao alocar memória para IA.");
    }
  }

  Future<Stream<String>> chat(String userMessage) async {
    try {
      if (!await _aiManager.isModelInstalled()) {
        return Stream.value("⚠️ IA não instalada. Vá em Preferências.");
      }

      await _loadModel();

      final smartContext = await _contextPanel.buildFinancialPersona();

      final promptText = """
<|begin_of_text|><|start_header_id|>system<|end_header_id|>
Você é o Arcis. Responda em Português.
CONTEXTO:
$smartContext
<|eot_id|>
<|start_header_id|>user<|end_header_id|>
$userMessage
<|eot_id|>
<|start_header_id|>assistant<|end_header_id|>
""";

      debugPrint("🤖 Prompt Local Enviado");

      // CORREÇÃO: Usando apenas o prompt nomeado.
      // Removemos 'temp', 'topK', etc. para evitar erros de API.
      // A biblioteca usará os padrões (geralmente temp 0.8).
      return _llama.generate(
        prompt: promptText, 
      );

    } catch (e) {
      return Stream.value("Erro: $e");
    }
  }
  
  void dispose() {
    _llama.dispose();
    _isModelLoaded = false;
  }
}