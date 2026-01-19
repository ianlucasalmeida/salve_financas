import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart'; 
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isScanComplete = false; 
  final MobileScannerController cameraController = MobileScannerController();

  /// EXTRAÇÃO TÉCNICA AVANÇADA (Padrão SEFAZ-PE e Nacional)
  Map<String, dynamic> _extractNfceData(String code) {
    double value = 0.0;
    String title = "Nota Fiscal Pendente";
    DateTime date = DateTime.now();
    String? accessKey;

    try {
      final uri = Uri.parse(code.trim());
      
      // 1. Extração da Data de Emissão (dhEmi) - Padrão: 2026-01-18T15:20:00-03:00
      final String? rawDate = uri.queryParameters['dhEmi'];
      if (rawDate != null) {
        // Converte o formato hexadecimal ou string ISO para DateTime
        date = DateTime.tryParse(rawDate) ?? DateTime.now();
      }

      // 2. Extração do Valor Total (vNF ou vTotal ou v)
      final possibleParams = ['vNF', 'vTotal', 'valor', 'v'];
      for (var param in possibleParams) {
        final val = uri.queryParameters[param];
        if (val != null) {
          value = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
          if (value > 0) break;
        }
      }

      // 3. Extração da Chave de Acesso (chNFe) e CNPJ
      // Em PE, pode vir dentro do parâmetro 'p' separado por '|'
      final String? pParam = uri.queryParameters['p'];
      if (pParam != null) {
        final parts = pParam.split('|');
        if (parts.isNotEmpty) accessKey = parts[0];
        if (value == 0 && parts.length >= 5) value = double.tryParse(parts[4]) ?? 0.0;
      }
      
      accessKey ??= uri.queryParameters['chNFe'];

      if (accessKey != null && accessKey.length >= 20) {
        final cnpj = accessKey.substring(6, 20);
        title = "LOJA CNPJ: $cnpj";
      }
    } catch (e) {
      debugPrint("Falha no Parser Arcis: $e");
    }

    return {
      'value': value, 
      'title': title, 
      'date': date,
      'key': accessKey,
      'url': code
    };
  }

  Future<void> _processNote(String code) async {
    if (_isScanComplete || !mounted) return;
    
    setState(() => _isScanComplete = true);
    
    try {
      // Hardware stop prevent BufferQueue errors
      await cameraController.stop(); 

      // Busca usuário com ID válido para isolamento
      final user = await isar.userModels.filter().idGreaterThan(0).findFirst();
      if (user == null) {
        context.go('/login'); // Segurança: Se não há usuário, volta ao login
        return;
      }

      final data = _extractNfceData(code);

      // REGRA DE NEGÓCIO: Registro completo no Banco de Dados
      final newTx = TransactionModel()
        ..userId = user.id 
        ..title = data['title']
        ..value = data['value']
        ..date = data['date']
        ..category = "Processando Itens..." // Placeholder para a IA processar o Scraping
        ..type = "expense"
        ..rawText = data['url']; // Salvamos a URL para a IA buscar os itens comprados

      await isar.writeTxn(() => isar.transactionModels.put(newTx));

      if (mounted) {
        _showSuccessNotification(data['value']);
        
        // CORREÇÃO DO CRASH: Navegação controlada
        if (Navigator.canPop(context)) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      debugPrint("Erro Crítico de Coleta: $e");
      if (mounted) {
        setState(() => _isScanComplete = false);
        cameraController.start();
      }
    }
  }

  void _showSuccessNotification(double val) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("SISTEMA: R\$ ${val.toStringAsFixed(2)} REGISTRADO COM SUCESSO"),
        backgroundColor: Colors.greenAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('CAPTURE TERMINAL', 
          style: TextStyle(fontFamily: 'monospace', fontSize: 13, letterSpacing: 3, color: Colors.greenAccent)),
        actions: [
          ValueListenableBuilder(
            valueListenable: cameraController,
            builder: (context, state, child) {
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(isTorchOn ? Icons.bolt : Icons.bolt_outlined, 
                  color: isTorchOn ? Colors.greenAccent : Colors.white10),
                onPressed: () => cameraController.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isScanComplete) {
                _processNote(barcodes.first.rawValue ?? "");
              }
            },
          ),
          
          // Design Central - Matrix Overlay
          _buildScannerOverlay(),

          if (_isScanComplete)
            const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent.withOpacity(0.2), width: 1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                children: [
                  _corner(top: true, left: true),
                  _corner(top: true, left: false),
                  _corner(top: false, left: true),
                  _corner(top: false, left: false),
                  Center(
                    child: Container(
                      width: 240, height: 1, 
                      color: Colors.greenAccent.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text("SCANNER FISCAL ATIVO", 
              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _corner({required bool top, required bool left}) {
    return Positioned(
      top: top ? 0 : null, bottom: !top ? 0 : null,
      left: left ? 0 : null, right: !left ? 0 : null,
      child: Container(
        width: 35, height: 35,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: Colors.greenAccent, width: 4) : BorderSide.none,
            bottom: !top ? const BorderSide(color: Colors.greenAccent, width: 4) : BorderSide.none,
            left: left ? const BorderSide(color: Colors.greenAccent, width: 4) : BorderSide.none,
            right: !left ? const BorderSide(color: Colors.greenAccent, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}