import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

class ScraperViewerScreen extends StatefulWidget {
  final String url;
  const ScraperViewerScreen({super.key, required this.url});

  @override
  State<ScraperViewerScreen> createState() => _ScraperViewerScreenState();
}

class _ScraperViewerScreenState extends State<ScraperViewerScreen> {
  double _progress = 0;
  bool _dataCaptured = false;
  String _status = "CONECTANDO AO SERVIDOR SEFAZ...";
  InAppWebViewController? webController;
  Timer? _sniperTimer;

  @override
  void dispose() {
    _sniperTimer?.cancel();
    super.dispose();
  }

  // O "Sniper": Roda a cada 1 segundo buscando padrões XML no código fonte
  void _startSniper() {
    _sniperTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_dataCaptured || webController == null) return;

      // Script JS injetado para ler o XML Bruto
      final result = await webController!.evaluateJavascript(source: r"""
        (function() {
          try {
            // Pega todo o conteúdo da página (O XML da SEFAZ)
            var content = document.documentElement.outerHTML;
            var items = [];
            var dataEmissao = null;

            // Verifica se é um XML de NFe (Tag raiz comum)
            if (content.includes('<nfeProc') || content.includes('<infNFe')) {
               
               // 1. Captura a Data (<dhEmi>)
               var dataMatch = content.match(/<dhEmi>(.*?)<\/dhEmi>/);
               if (dataMatch) dataEmissao = dataMatch[1];

               // 2. Quebra o XML em blocos de produto (<det ... </det>)
               var detalhes = content.split('<det');
               
               // Começa do índice 1 para pular o cabeçalho inicial
               for (var i = 1; i < detalhes.length; i++) {
                  var pedaco = detalhes[i];
                  
                  // Regex para extrair os campos exatos do seu XML
                  var nome = pedaco.match(/<xProd>(.*?)<\/xProd>/);
                  var valor = pedaco.match(/<vProd>(.*?)<\/vProd>/); // Valor total do item
                  var qtd = pedaco.match(/<qCom>(.*?)<\/qCom>/);     // Quantidade

                  if (nome && valor) {
                     items.push({
                       n: nome[1],
                       v: valor[1],
                       q: qtd ? qtd[1] : '1'
                     });
                  }
               }
               
               if (items.length > 0) {
                 return JSON.stringify({
                    type: 'xml', 
                    date: dataEmissao,
                    data: items
                 });
               }
            }
            return null;
          } catch(e) { return null; }
        })();
      """);

      if (result != null) {
        _handleSuccess(result.toString());
      }
    });
  }

  void _handleSuccess(String jsonString) {
    if (_dataCaptured) return;
    setState(() {
      _dataCaptured = true;
      _status = "XML VALIDADO! PROCESSANDO...";
    });
    
    // Pequeno delay para feedback visual antes de fechar
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) context.pop(jsonString); // Retorna o JSON para a tela anterior
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.greenAccent), 
          onPressed: () => context.pop() // Botão de cancelar manual
        ),
        title: Text(_status, 
          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.greenAccent, letterSpacing: 1)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(value: _progress, color: Colors.greenAccent, backgroundColor: Colors.white10),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useWideViewPort: true,
              loadWithOverviewMode: true,
              // User Agent Genérico para evitar bloqueios de WAF
              userAgent: "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0 Mobile Safari/537.36",
            ),
            onWebViewCreated: (controller) {
              webController = controller;
              _startSniper(); // Inicia a busca automática
            },
            onProgressChanged: (controller, progress) {
              setState(() => _progress = progress / 100);
              if (progress > 90) setState(() => _status = "ANALISANDO DADOS FISCAIS...");
            },
          ),
          
          // Máscara escura para manter o design técnico enquanto o XML branco carrega no fundo
          if (!_dataCaptured)
            IgnorePointer(
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
        ],
      ),
    );
  }
}