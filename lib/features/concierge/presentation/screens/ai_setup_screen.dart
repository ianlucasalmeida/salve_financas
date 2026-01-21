import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salve_financas/features/concierge/services/ai_manager_service.dart';

class AiSetupScreen extends StatefulWidget {
  const AiSetupScreen({super.key});

  @override
  State<AiSetupScreen> createState() => _AiSetupScreenState();
}

class _AiSetupScreenState extends State<AiSetupScreen> {
  final AiManagerService _manager = AiManagerService();
  double _progress = 0.0;
  bool _downloading = false;
  String _status = "MÓDULO DE INTELIGÊNCIA LOCAL";

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _status = "BAIXANDO CÉREBRO NEURAL (800MB)...";
    });

    try {
      await _manager.downloadModel(onProgress: (p) {
        setState(() => _progress = p);
      });
      
      if (mounted) {
        context.go('/concierge'); // Vai para o chat real
      }
    } catch (e) {
      setState(() {
        _downloading = false;
        _status = "ERRO NO DOWNLOAD. TENTE WI-FI.";
        _progress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology, size: 80, color: Colors.greenAccent),
            const SizedBox(height: 32),
            const Text(
              "ATIVAR ARCIS AI",
              style: TextStyle(
                fontFamily: 'monospace', 
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Para garantir sua privacidade, o Arcis roda 100% no seu aparelho. Precisamos baixar o modelo neural (Llama 3.2 - 800MB) uma única vez.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 48),
            
            if (_downloading) ...[
              LinearProgressIndicator(
                value: _progress, 
                color: Colors.greenAccent, 
                backgroundColor: Colors.white10,
                minHeight: 10,
              ),
              const SizedBox(height: 16),
              Text("${(_progress * 100).toInt()}% CONCLUÍDO", 
                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
            ] else ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _startDownload,
                child: const Text("BAIXAR E ATIVAR", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => context.go('/dash'),
                child: const Text("AGORA NÃO", style: TextStyle(color: Colors.grey)),
              )
            ],
            
            const SizedBox(height: 20),
            Text(_status, 
              style: TextStyle(color: _downloading ? Colors.white54 : Colors.transparent, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}