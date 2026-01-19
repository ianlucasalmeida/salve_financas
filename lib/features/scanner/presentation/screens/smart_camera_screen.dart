import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../widgets/scanner_overlay.dart';

class SmartCameraScreen extends StatefulWidget {
  const SmartCameraScreen({super.key});

  @override
  State<SmartCameraScreen> createState() => _SmartCameraScreenState();
}

class _SmartCameraScreenState extends State<SmartCameraScreen> {
  bool isProcessing = false;
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("CAPTURA INTELIGENTE"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off: return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on: return const Icon(Icons.flash_on, color: Color(0xFF00E676));
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Câmera
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.contains('sefaz')) {
                  _processSefazUrl(barcode.rawValue!);
                }
              }
            },
          ),

          // 2. Overlay de Scan (Verde Neon)
          const ScannerOverlay(),

          // 3. Indicador de Processamento
          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00E676)),
                    const SizedBox(height: 20),
                    Text(
                      "SINCRONIZANDO COM SEFAZ...",
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            
          // 4. Botão para captura manual (OCR Fallback)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                backgroundColor: theme.primaryColor,
                onPressed: () => _captureAndOcr(), 
                label: const Text("FOTO DA NOTA (OCR)", style: TextStyle(color: Colors.black)),
                icon: const Icon(Icons.camera_alt, color: Colors.black),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _processSefazUrl(String url) async {
    setState(() => isProcessing = true);
    // Aqui chamamos o Service de Scraper que criaremos abaixo
    print("URL Detectada: $url");
    // Simulando delay de rede
    await Future.delayed(const Duration(seconds: 2));
    setState(() => isProcessing = false);
    // Navegar para confirmação de dados...
  }

  void _captureAndOcr() {
     // Lógica para disparar o OCR caso o QR Code esteja ilegível
  }
}