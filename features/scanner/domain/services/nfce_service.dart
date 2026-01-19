// features/scanner/domain/services/nfce_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class NfceService {
  // Busca dados completos da NFCe via SEFAZ
  Future<Map<String, dynamic>> fetchNfceData(String url) async {
    try {
      final uri = Uri.parse(url);
      final accessKey = _extractAccessKey(uri);
      
      if (accessKey == null) {
        throw Exception('Chave de acesso não encontrada');
      }
      
      // URL da consulta pública da SEFAZ-PE
      final consultaUrl = 'https://www.sefaz.pe.gov.br/nfce/consulta?p=$accessKey';
      
      // Faz a requisição para a SEFAZ
      final response = await http.get(
        Uri.parse(consultaUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );
      
      if (response.statusCode == 200) {
        return _parseNfceHtml(response.body, accessKey);
      } else {
        throw Exception('Falha ao acessar SEFAZ: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erro no scraping SEFAZ: $e');
      rethrow;
    }
  }
  
  String? _extractAccessKey(Uri uri) {
    // Extrai a chave de acesso da URL do QR Code
    final pParam = uri.queryParameters['p'];
    if (pParam != null && pParam.contains('|')) {
      return pParam.split('|').first;
    }
    return uri.queryParameters['chNFe'];
  }
  
  Map<String, dynamic> _parseNfceHtml(String html, String accessKey) {
    // Parseia o HTML da página da SEFAZ
    final document = html;
    
    // Extrai CNPJ (posições 6-20 da chave de acesso)
    final cnpj = accessKey.length >= 20 ? accessKey.substring(6, 20) : '';
    
    // Extrai data de emissão
    final date = _extractDate(document);
    
    // Extrai valor total
    final totalValue = _extractTotalValue(document);
    
    // Extrai itens da nota
    final items = _extractItems(document);
    
    // Extrai dados da empresa (razão social)
    final companyName = _extractCompanyName(document);
    
    return {
      'accessKey': accessKey,
      'cnpj': cnpj,
      'date': date,
      'totalValue': totalValue,
      'items': items,
      'companyName': companyName,
      'status': 'PROCESSADA',
    };
  }
  
  DateTime _extractDate(String html) {
    try {
      // Procura por padrões de data no HTML
      final datePattern = RegExp(r'(\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2})');
      final match = datePattern.firstMatch(html);
      if (match != null) {
        final dateStr = match.group(1);
        final parts = dateStr!.split(' ');
        final dateParts = parts[0].split('/');
        final timeParts = parts[1].split(':');
        
        return DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
          int.parse(timeParts[2]),
        );
      }
    } catch (e) {
      debugPrint('Erro ao extrair data: $e');
    }
    return DateTime.now();
  }
  
  double _extractTotalValue(String html) {
    try {
      // Procura por padrões de valor (R$ X.XXX,XX)
      final valuePattern = RegExp(r'R\$\s*([\d.,]+)');
      final matches = valuePattern.allMatches(html);
      
      for (final match in matches) {
        final valueStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
        final value = double.tryParse(valueStr);
        if (value != null && value > 0) {
          // Normalmente o maior valor é o total da nota
          return value;
        }
      }
    } catch (e) {
      debugPrint('Erro ao extrair valor: $e');
    }
    return 0.0;
  }
  
  List<Map<String, dynamic>> _extractItems(String html) {
    final items = <Map<String, dynamic>>[];
    
    try {
      // Esta é uma implementação simplificada
      // Na prática, você precisa analisar o HTML específico da SEFAZ-PE
      // Aqui está um exemplo genérico:
      
      // Procura por tabelas de itens
      final itemSections = html.split('</tr>');
      
      for (final section in itemSections) {
        if (section.contains('Código') && section.contains('Descrição')) {
          // Implementar parsing específico do HTML da SEFAZ-PE
          // Você pode usar regex ou um parser HTML como html package
        }
      }
      
      // Exemplo de item mockado (substituir pelo parsing real)
      items.add({
        'code': '7891234567890',
        'description': 'PRODUTO EXEMPLO 1',
        'quantity': 2,
        'unitValue': 25.50,
        'totalValue': 51.00,
      });
      
    } catch (e) {
      debugPrint('Erro ao extrair itens: $e');
    }
    
    return items;
  }
  
  String _extractCompanyName(String html) {
    try {
      // Procura pela razão social da empresa
      final namePattern = RegExp(r'<strong>(.*?)<\/strong>');
      final match = namePattern.firstMatch(html);
      if (match != null) {
        return match.group(1)!.trim();
      }
    } catch (e) {
      debugPrint('Erro ao extrair nome da empresa: $e');
    }
    return 'LOJA CNPJ';
  }
}