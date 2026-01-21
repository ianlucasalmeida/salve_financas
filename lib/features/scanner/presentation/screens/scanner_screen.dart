import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:salve_financas/main.dart'; 
import 'package:salve_financas/features/dashboard/data/models/transaction_model.dart';
import 'package:salve_financas/features/auth/data/models/user_model.dart';
import 'package:salve_financas/core/services/headless_scraper_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;
  String _statusText = "SISTEMA PRONTO";
  
  final MobileScannerController cameraController = MobileScannerController();
  final HeadlessScraperService _headlessService = HeadlessScraperService();

  Future<void> _processQrCode(String code) async {
    if (_isProcessing || code.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusText = "EXTRAINDO DADOS (SEFAZ)...";
    });

    try {
      await cameraController.stop();

      final user = await isar.userModels.filter().idGreaterThan(0).findFirst();
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }

      // --- 1. TENTATIVA SCRAPING INVISÍVEL ---
      // Agora retorna um mapa completo com CNPJ, Total, Pagamento, etc.
      final Map<String, dynamic> result = await _headlessService.scrapeInvisible(code);
      
      List<TransactionItem> items = result['items'] ?? [];
      double totalValue = double.tryParse(result['total']?.toString() ?? "0") ?? 0.0;
      String cnpj = result['cnpj']?.toString() ?? "";
      String paymentMethod = result['payment']?.toString() ?? "";
      String rawDate = result['date']?.toString() ?? "";
      
      DateTime finalDate = DateTime.now();
      if (rawDate.isNotEmpty) {
        finalDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      }

      // --- 2. FALLBACK DA URL (Se o Scraping falhar/retornar 0) ---
      if (totalValue == 0) {
        debugPrint("Scraping falhou (Zero), tentando decodificar URL...");
        try {
          final uri = Uri.parse(code.trim());
          
          // Tenta pegar o parâmetro 'p' (comum em PE)
          // Ex: ...?p=CHAVE|2|1|1|VALOR|...
          final p = uri.queryParameters['p'];
          if (p != null) {
            final parts = p.split('|');
            // O valor total costuma ser o índice 4 ou 5
            if (parts.length >= 5) {
               totalValue = double.tryParse(parts[4].replaceAll(',', '.')) ?? 0.0;
            }
            // CNPJ está na chave de acesso (primeira parte)
            if (parts.isNotEmpty && parts[0].length == 44) {
               cnpj = parts[0].substring(6, 20); // Posição fixa do CNPJ na chave
            }
          } else {
            // Tenta parâmetros explícitos
            String? v = uri.queryParameters['vNF'] ?? uri.queryParameters['vTotal'];
            if (v != null) totalValue = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
          }
        } catch (e) {
          debugPrint("Erro Fallback URL: $e");
        }
      }

      // --- 3. MONTAGEM FINAL DO DADO ---
      String title = items.isNotEmpty 
          ? "COMPRA: ${items.length} ITENS" 
          : (cnpj.isNotEmpty ? "LOJA CNPJ: $cnpj" : "NOTA FISCAL");

      // Adiciona o método de pagamento no título ou categoria se existir
      if (paymentMethod.isNotEmpty) {
        title += " ($paymentMethod)";
      }

      final newTx = TransactionModel()
        ..userId = user.id
        ..title = title
        ..value = totalValue
        ..date = finalDate
        ..category = items.isNotEmpty ? "Mercado" : "Scanner Pendente"
        ..type = "expense"
        ..rawText = code // Salva a URL original para debug
        ..items = items;

      await isar.writeTxn(() => isar.transactionModels.put(newTx));

      if (mounted) {
        String msg = totalValue > 0 
            ? "SUCESSO: R\$ ${totalValue.toStringAsFixed(2)}" 
            : "NOTA SALVA (PENDENTE)";
            
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: totalValue > 0 ? Colors.greenAccent : Colors.orangeAccent,
          duration: const Duration(seconds: 3),
        ));
        
        context.go('/dash');
      }

    } catch (e) {
      debugPrint("Erro Crítico Scanner: $e");
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = "ERRO. TENTE NOVAMENTE.";
        });
        cameraController.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (c) => _processQrCode(c.barcodes.first.rawValue ?? ""),
          ),
          
          if (!_isProcessing)
             Center(child: Container(
               width: 280, height: 280, 
               decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent, width: 2))
             )),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.greenAccent),
                    const SizedBox(height: 20),
                    Text(_statusText, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}