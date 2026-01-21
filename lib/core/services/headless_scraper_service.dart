import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../features/dashboard/data/models/transaction_model.dart';

class HeadlessScraperService {
  
  Future<Map<String, dynamic>> scrapeInvisible(String url) async {
    final Completer<Map<String, dynamic>> completer = Completer();
    late HeadlessInAppWebView headlessWebView;
    Timer? timeoutTimer;
    bool hasCompleted = false;

    void finish(Map<String, dynamic> result) {
      if (!hasCompleted) {
        hasCompleted = true;
        timeoutTimer?.cancel();
        if (!completer.isCompleted) completer.complete(result);
        Future.delayed(const Duration(seconds: 1), () => headlessWebView.dispose());
      }
    }

    try {
      headlessWebView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
          useWideViewPort: true,
          loadWithOverviewMode: true,
          userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
        ),
        onReceivedServerTrustAuthRequest: (controller, challenge) async {
          return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
        },
        onLoadStop: (controller, url) async {
          try {
            await Future.delayed(const Duration(seconds: 4)); // Tempo para XSLT

            final jsResult = await controller.evaluateJavascript(source: r"""
              (function() {
                try {
                  var htmlContent = document.documentElement.outerHTML;
                  var textContent = document.body ? document.body.innerText : "";
                  
                  // --- FUNÇÃO DE LIMPEZA FINANCEIRA (CRÍTICA) ---
                  function parseMoney(str) {
                    if (!str) return 0.0;
                    // Remove R$, espaços e caracteres estranhos
                    var clean = str.replace(/[^\d,.]/g, '').trim();
                    
                    // Caso 1: 1.200,50 (Padrão BR)
                    if (clean.includes(',') && clean.includes('.')) {
                       clean = clean.replace(/\./g, '').replace(',', '.');
                    } 
                    // Caso 2: 1200,50 (Sem milhar)
                    else if (clean.includes(',')) {
                       clean = clean.replace(',', '.');
                    }
                    
                    return parseFloat(clean) || 0.0;
                  }

                  var data = { 
                    items: [], 
                    total: 0.0, 
                    cnpj: '', 
                    date: '',
                    debug_type: 'unknown'
                  };

                  // --- ESTRATÉGIA 1: XML (Se disponível) ---
                  if (htmlContent.includes('<nfeProc') || htmlContent.includes('<infNFe')) {
                     data.debug_type = 'XML';
                     var vnfMatch = htmlContent.match(/<vNF>([\d.]+)<\/vNF>/) || htmlContent.match(/<vTotal>([\d.]+)<\/vTotal>/);
                     if (vnfMatch) data.total = parseFloat(vnfMatch[1]);
                     
                     var dets = htmlContent.split('<det');
                     for (var i = 1; i < dets.length; i++) {
                        var chunk = dets[i];
                        var nome = chunk.match(/<xProd>(.*?)<\/xProd>/);
                        var valor = chunk.match(/<vProd>(.*?)<\/vProd>/); 
                        if (nome && valor) {
                           data.items.push({ 
                             n: nome[1], 
                             v: parseFloat(valor[1]), // XML já vem com ponto (10.99)
                             q: 1.0 
                           });
                        }
                     }
                  } 
                  
                  // --- ESTRATÉGIA 2: HTML VISUAL (O seu caso atual) ---
                  else {
                     data.debug_type = 'HTML';
                     
                     // Busca linhas de tabela (Padrão NFC-e ou Genérico)
                     var rows = document.querySelectorAll('tr[id^="Item"], #tabResult tr, .table-striped tbody tr, table tbody tr');
                     
                     for (var row of rows) {
                        var txt = row.innerText;
                        
                        // Nome: Procura classes comuns ou pega texto inicial
                        var nomeEl = row.querySelector('.txtTit, .xProd, span.truncate, .prod-desc');
                        var nome = nomeEl ? nomeEl.innerText : txt.split(/\d/)[0]; // Pega texto antes do primeiro número
                        
                        // Valor: Pega o ÚLTIMO valor monetário da linha (geralmente é o total)
                        // Regex procura formato 0,00 ou 0.00
                        var prices = txt.match(/[\d]{1,3}(?:[.,]\d{3})*[.,]\d{2}/g);
                        
                        if (nome && prices && prices.length > 0) {
                           var rawPrice = prices[prices.length - 1]; // Último preço é o Total
                           var v = parseMoney(rawPrice);
                           
                           // Ignora itens com valor 0 ou nomes inúteis (cabeçalho)
                           if (v > 0 && nome.length > 2 && !nome.includes('Valor') && !nome.includes('Total')) {
                              data.items.push({ 
                                n: nome.replace(/\n/g, ' ').trim(), 
                                v: v, 
                                q: 1.0 
                              });
                           }
                        }
                     }

                     // Busca Total Global (Fallback) se a soma dos itens der zero
                     if (data.items.length === 0) {
                        var totalMatch = textContent.match(/Total\s*:?\s*R?\$\s*([\d.,]+)/i);
                        if (totalMatch) data.total = parseMoney(totalMatch[1]);
                     } else {
                        // Recalcula total somando os itens extraídos (Mais seguro)
                        data.total = data.items.reduce((acc, item) => acc + item.v, 0);
                     }
                  }

                  return JSON.stringify(data);
                } catch(e) { 
                  return JSON.stringify({error: e.toString()}); 
                }
              })();
            """);

            if (jsResult != null) {
              final parsed = jsonDecode(jsResult.toString());
              debugPrint("🔎 TIPO DETECTADO: ${parsed['debug_type']}");
              
              List<TransactionItem> items = [];
              if (parsed['items'] != null) {
                for (var i in parsed['items']) {
                  items.add(TransactionItem()
                    ..name = i['n'].toString().toUpperCase().trim()
                    ..totalPrice = double.tryParse(i['v'].toString()) ?? 0.0
                    ..quantity = 1.0
                    ..unitPrice = double.tryParse(i['v'].toString()) ?? 0.0
                  );
                }
              }

              finish({
                'items': items,
                'total': double.tryParse(parsed['total'].toString()) ?? 0.0,
                'cnpj': parsed['cnpj']?.toString() ?? '',
                'date': ''
              });
            } else {
              finish({});
            }
          } catch (e) {
            debugPrint("Headless Exception: $e");
            finish({});
          }
        },
      );

      await headlessWebView.run();
      timeoutTimer = Timer(const Duration(seconds: 45), () => finish({}));
      return completer.future;

    } catch (e) {
      return {};
    }
  }
}