import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart';
import 'package:salve_financas/core/data/models/app_config_model.dart';
import 'package:salve_financas/features/concierge/services/ai_manager_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AiManagerService _aiManager = AiManagerService();
  bool _highPerf = true;
  bool _isModelPresent = false;
  bool _downloading = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await isar.appConfigModels.where().findFirst();
    final present = await _aiManager.isModelInstalled();
    
    if (mounted) {
      setState(() {
        _highPerf = config?.highPerformanceMode ?? true;
        _isModelPresent = present;
      });
    }
  }

  // --- ALTERAÇÃO PRINCIPAL AQUI ---
  Future<void> _togglePerformance(bool value) async {
    // 1. Salva a nova preferência no banco
    await isar.writeTxn(() async {
      final config = await isar.appConfigModels.where().findFirst() ?? AppConfigModel();
      config.highPerformanceMode = value;
      await isar.appConfigModels.put(config);
    });

    // 2. Atualiza visualmente o switch
    setState(() => _highPerf = value);

    if (mounted) {
      // 3. Exibe Alerta de Reinício Obrigatório 
      // Isso impede que o app tente recarregar a IA na hora e estoure a memória
      showDialog(
        context: context,
        barrierDismissible: false, // Usuário é obrigado a clicar no botão
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF222222),
          title: const Text("Reinicialização Necessária", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            "Para alterar a alocação de memória do Cérebro Neural com segurança, é necessário reiniciar o aplicativo.\n\nPor favor, feche o app e abra novamente.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fecha o dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Configuração salva. Reinicie o app agora."),
                    backgroundColor: Colors.amber,
                  ),
                );
              },
              child: const Text("Entendi", style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        ),
      );
    }
  }
  // --------------------------------

  Future<void> _downloadAi() async {
    setState(() => _downloading = true);
    
    int lastPercentage = 0;

    try {
      await _aiManager.downloadModel(onProgress: (p) {
        final currentPercentage = (p * 100).toInt();
        if (currentPercentage > lastPercentage) {
          lastPercentage = currentPercentage;
          if (mounted) setState(() => _progress = p);
        }
      });
      
      if (mounted) {
        setState(() {
          _isModelPresent = true;
          _downloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Download Concluído! Sistema pronto."),
          backgroundColor: Colors.green,
        ));
      }
      
    } catch (e) {
      if (mounted) {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro no download. Verifique o Wi-Fi.")));
      }
    }
  }

  Future<void> _deleteAi() async {
    try {
      final path = await _aiManager.getModelPath();
      final file = File(path);
      
      if (await file.exists()) {
        await file.delete();
      }

      if (mounted) {
        setState(() {
          _isModelPresent = false;
          _progress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Cérebro deletado. Baixe novamente para corrigir erros."),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (e) {
      debugPrint("Erro ao deletar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("CONFIGURAÇÕES DO SISTEMA", style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
        backgroundColor: const Color(0xFF111111),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("NÚCLEO DE INTELIGÊNCIA (AI)"),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isModelPresent ? Colors.greenAccent : Colors.redAccent),
            ),
            child: Row(
              children: [
                Icon(_isModelPresent ? Icons.check_circle : Icons.error, color: _isModelPresent ? Colors.greenAccent : Colors.redAccent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_isModelPresent ? "CÉREBRO INSTALADO" : "CÉREBRO AUSENTE", 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_isModelPresent ? "Llama 3.2 1B (800MB)" : "Necessário download para funcionar.", 
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                if (!_downloading)
                  IconButton(
                    icon: Icon(
                      _isModelPresent ? Icons.delete_forever : Icons.download, 
                      color: _isModelPresent ? Colors.redAccent : Colors.white
                    ),
                    onPressed: _isModelPresent ? _deleteAi : _downloadAi,
                  )
              ],
            ),
          ),

          if (_downloading) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: _progress, color: Colors.greenAccent, backgroundColor: Colors.white10),
            Text("${(_progress * 100).toInt()}%", textAlign: TextAlign.right, style: const TextStyle(color: Colors.greenAccent)),
          ],

          const SizedBox(height: 24),
          _sectionTitle("PERFORMANCE DE HARDWARE"),

          SwitchListTile(
            value: _highPerf,
            activeColor: Colors.greenAccent,
            tileColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text("Alocação Máxima (1.5GB)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text(
              "Aumenta a inteligência da IA. Desligue se o app fechar sozinho.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onChanged: _togglePerformance,
          ),
          
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Nota: Ao alterar essa opção, reinicie o app para limpar a memória RAM antiga.",
              style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', letterSpacing: 1.5, fontSize: 12)),
    );
  }
}