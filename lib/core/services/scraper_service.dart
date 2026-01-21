import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../../features/dashboard/data/models/transaction_model.dart';

class ScraperService {
  /// Tenta baixar o HTML da nota e extrair os produtos
  Future<List<TransactionItem>> scrapeItems(String url) async {
    List<TransactionItem> extractedItems = [];

    try {
      // 1. Simula um navegador Mobile para pegar a versão leve do site
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "User-Agent": "Mozilla/5.0 (Linux; Android 10; SM-G960F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.181 Mobile Safari/537.36"
        },
      );

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);

        // 2. Lógica de Busca (Seletores CSS para SEFAZ-PE e Padrão Nacional)
        // Geralmente os itens ficam em uma <table> com id="tabResult" ou classes específicas
        
        // Tentativa 1: Busca por linhas de tabela padrão NFC-e
        var rows = document.querySelectorAll('tr[id^="Item"]'); 
        
        if (rows.isEmpty) {
          // Tentativa 2: Busca genérica por tabela de itens
          rows = document.querySelectorAll('#tabResult tr');
        }

        for (var row in rows) {
          try {
            // Extração de Nome (Geralmente num <span class="txtTit"> ou primeira célula)
            String name = row.querySelector('.txtTit')?.text.trim() ?? 
                          row.querySelectorAll('td')[0].text.trim();

            // Extração de Valores (Geralmente classe .Rqtd, .RvlUnit)
            String qtdText = row.querySelector('.Rqtd')?.text ?? "";
            String valText = row.querySelector('.valor')?.text ?? ""; // Valor Total do Item

            // Limpeza de Strings (Trocar vírgula por ponto, remover "Qtde:", etc)
            double qtd = _cleanDouble(qtdText);
            double total = _cleanDouble(valText);

            if (name.isNotEmpty) {
              extractedItems.add(TransactionItem()
                ..name = name
                ..quantity = qtd > 0 ? qtd : 1.0
                ..totalPrice = total
                ..unitPrice = (total / (qtd > 0 ? qtd : 1))
              );
            }
          } catch (e) {
            // Ignora item com erro de parse individual
            continue; 
          }
        }
      }
    } catch (e) {
      print("Erro no Scraping Local: $e");
    }

    return extractedItems;
  }

  double _cleanDouble(String text) {
    // Remove tudo que não é número ou vírgula
    String clean = text.replaceAll(RegExp(r'[^0-9,]'), '');
    return double.tryParse(clean.replaceAll(',', '.')) ?? 0.0;
  }
}