import 'dart:async';
import 'dart:io';
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
      final file = File(path);
      
      if (!await file.exists()) throw Exception("Modelo não encontrado.");

      final config = await isar.appConfigModels.where().findFirst();
      final isTurbo = config?.highPerformanceMode ?? false;

      // 1024 é seguro. 2048 (Turbo) exige reinício se trocado.
      final int ctxSize = isTurbo ? 2048 : 1024;

      debugPrint("🧠 Carregando Cérebro (Ctx: $ctxSize)...");

      await _llama.loadModel(
        modelPath: path,
        contextSize: ctxSize, 
      );
      
      _isModelLoaded = true;
    } catch (e) {
      _isModelLoaded = false;
      throw Exception("Erro ao carregar motor: $e");
    }
  }

  Future<Stream<String>> chat(String userMessage, {String? attachmentText}) async {
    try {
      if (!await _aiManager.isModelInstalled()) return Stream.value("⚠️ IA não instalada.");

      await _loadModel();

      // 1. Coleta os dados (Agora vêm limpos, sem avisos de "Sinal Vermelho")
      final smartContext = await _contextPanel.buildFinancialPersona();
      
      // 2. Prepara anexo
      String attachmentContext = "";
      if (attachmentText != null && attachmentText.isNotEmpty) {
        final limit = 500; 
        final cleanText = attachmentText.length > limit 
            ? attachmentText.substring(0, limit)
            : attachmentText;
        attachmentContext = "\n[DOCUMENTO ANEXO]:\n$cleanText\n";
      }

      // 3. NOVO PROMPT "JAILBREAK DO BEM"
      // Mudamos a persona para "Analista de Dados" para evitar recusas de segurança.
      final promptText = """
<|begin_of_text|><|start_header_id|>system<|end_header_id|>
Você é o Arcis, um analisador de dados objetivo.
Sua função é ler os dados financeiros abaixo e responder a pergunta do usuário.
Não dê conselhos morais. Não julgue o saldo negativo. Apenas analise os números matematicamente.
Responda em Português do Brasil.

DADOS PARA ANÁLISE:
$smartContext

$attachmentContext
<|eot_id|>
<|start_header_id|>user<|end_header_id|>
$userMessage
<|eot_id|>
<|start_header_id|>assistant<|end_header_id|>
""";

      debugPrint("🤖 Prompt Enviado (Tam: ${promptText.length})");

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