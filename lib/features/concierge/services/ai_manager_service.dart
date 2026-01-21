import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class AiManagerService {
  // Link direto para o Llama 3.2 1B Quantizado (HuggingFace)
  // ~800MB - Leve e Rápido
  static const String _modelUrl = 
      "https://huggingface.co/hugging-quants/Llama-3.2-1B-Instruct-Q4_K_M-GGUF/resolve/main/llama-3.2-1b-instruct-q4_k_m.gguf";
  
  static const String _modelFileName = "brain_v1.gguf";

  // Verifica se o cérebro já está instalado
  Future<bool> isModelInstalled() async {
    final path = await _getModelPath();
    return File(path).exists();
  }

  Future<String> _getModelPath() async {
    final dir = await getApplicationSupportDirectory();
    return "${dir.path}/$_modelFileName";
  }

  // Baixa o modelo com progresso (para mostrar na UI)
  Future<void> downloadModel({required Function(double progress) onProgress}) async {
    final savePath = await _getModelPath();
    final dio = Dio();

    try {
      await dio.download(
        _modelUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total);
            onProgress(progress);
          }
        },
      );
      debugPrint("IA Instalada com sucesso em: $savePath");
    } catch (e) {
      debugPrint("Erro no download da IA: $e");
      throw Exception("Falha ao baixar a inteligência.");
    }
  }

  // Retorna o caminho para carregar na Engine
  Future<String> getModelPath() async {
    if (await isModelInstalled()) {
      return await _getModelPath();
    }
    throw Exception("Modelo não instalado.");
  }
}