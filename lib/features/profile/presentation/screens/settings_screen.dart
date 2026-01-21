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
        _highPerf = config?.highPerformanceMode ?? true; // Padrão TRUE (1.5GB)
        _isModelPresent = present;
      });
    }
  }

  Future<void> _togglePerformance(bool value) async {
    setState(() => _highPerf = value);
    
    // Salva no banco
    await isar.writeTxn(() async {
      final config = await isar.appConfigModels.where().findFirst() ?? AppConfigModel();
      config.highPerformanceMode = value;
      await isar.appConfigModels.put(config);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(value ? "Modo Turbo Ativado (Alocando 1.5GB)" : "Modo Econômico Ativado"),
        backgroundColor: Colors.greenAccent,
      ));
    }
  }

  Future<void> _downloadAi() async {
    setState(() => _downloading = true);
    try {
      await _aiManager.downloadModel(onProgress: (p) => setState(() => _progress = p));
      setState(() {
        _isModelPresent = true;
        _downloading = false;
      });
    } catch (e) {
      setState(() => _downloading = false);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro no download")));
    }
  }

  Future<void> _deleteAi() async {
    // Implementar logica de delete no AiManager se necessário, ou apenas sobrescrever
    // Por enquanto, apenas avisar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Limpeza de cache em breve.")));
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
          
          // Card de Status do Modelo
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
                if (!_isModelPresent && !_downloading)
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: _downloadAi,
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

          // Switch de Memória RAM
          SwitchListTile(
            value: _highPerf,
            activeColor: Colors.greenAccent,
            tileColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text("Alocação Máxima (1.5GB)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text(
              "Aumenta o contexto e a inteligência da IA. Requer mais RAM do dispositivo.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onChanged: _togglePerformance,
          ),
          
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Nota: Se o aplicativo fechar sozinho durante a conversa, desligue a opção acima.",
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