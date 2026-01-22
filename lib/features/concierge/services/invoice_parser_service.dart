import 'package:flutter/foundation.dart';

class ParsedTransaction {
  final String description;
  final double value;
  final DateTime date;
  final String originalLine;

  ParsedTransaction({
    required this.description,
    required this.value,
    required this.date,
    required this.originalLine,
  });
}

class InvoiceParserService {
  
  // Lista de palavras que NÃO são nomes de lojas (Ruído)
  final List<String> _noiseWords = [
    'COMPRA', 'PAGAMENTO', 'DEBITO', 'CREDITO', 'SALDO', 'TOTAL', 
    'ITENS', 'PARCELA', 'AUTORIZACAO', 'ESTABELECIMENTO', 'DATA', 
    'VALOR', 'DOC', 'TERMINAL', 'CARTAO', 'FINAL', 'BR', 'IOF'
  ];

  /// Processa o texto bruto extraído (OCR/PDF) e tenta estruturar em transações
  List<ParsedTransaction> parseRawText(String rawText) {
    List<ParsedTransaction> transactions = [];
    
    // Quebra em linhas e remove linhas vazias
    final lines = rawText.split('\n').where((l) => l.trim().isNotEmpty).toList();

    for (var line in lines) {
      // 1. Tenta encontrar um valor monetário na linha
      final value = _extractValue(line);
      
      // 2. Tenta encontrar uma data
      final date = _extractDate(line);

      // Se achou valor (e opcionalmente data), é uma linha candidata
      if (value != null && value > 0) {
        // 3. Limpa a descrição
        String description = _cleanDescription(line);

        // Validação extra: Se a descrição sobrou vazia ou só tem números, ignora
        if (description.length > 2 && !RegExp(r'^\d+$').hasMatch(description)) {
          transactions.add(ParsedTransaction(
            description: description,
            value: value, // Mantém positivo por enquanto, lógica de entrada/saída é externa
            date: date ?? DateTime.now(),
            originalLine: line,
          ));
        }
      }
    }
    
    return transactions;
  }

  /// CORREÇÃO DO BUG DOS 60 MIL: Parser Rígido de Moeda BRL
  double? _extractValue(String line) {
    try {
      // Regex para pegar o padrão monetário no final ou meio da linha
      // Aceita: 1.200,50 | 600,00 | 12.50
      final regex = RegExp(r'(?:R\$|RS|\$)?\s*(\d{1,3}(?:\.\d{3})*,\d{2}|\d+\.\d{2})');
      final match = regex.firstMatch(line);

      if (match != null) {
        String rawNum = match.group(1)!;

        // Se tem vírgula, é formato BR (1.000,00 ou 600,00)
        if (rawNum.contains(',')) {
          // Remove pontos de milhar (1.200,50 -> 1200,50)
          rawNum = rawNum.replaceAll('.', '');
          // Troca vírgula por ponto (1200,50 -> 1200.50)
          rawNum = rawNum.replaceAll(',', '.');
        } 
        // Se NÃO tem vírgula, mas tem ponto, assumimos que é decimal se tiver 2 casas
        // Cuidado: OCR as vezes lê 1000 como 1.000. 
        // A lógica segura para BRL é sempre confiar na vírgula como decimal.
        
        return double.parse(rawNum);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Remove datas, valores e palavras proibidas para sobrar só a Loja
  String _cleanDescription(String line) {
    // Remove o valor (R$ ...)
    String clean = line.replaceAll(RegExp(r'(?:R\$|RS|\$)?\s*\d+[.,]?\d*'), '');
    
    // Remove datas (dd/mm)
    clean = clean.replaceAll(RegExp(r'\d{2}/\d{2}(?:/\d{2,4})?'), '');

    // Remove caracteres especiais irrelevantes, mantendo letras, espaços e hífens
    clean = clean.replaceAll(RegExp(r'[^\w\s\-]'), '');

    // Remove palavras de ruído (Blacklist)
    final words = clean.split(' ');
    final filteredWords = words.where((w) {
      final wordUpper = w.toUpperCase().trim();
      if (wordUpper.length < 2) return false; // Remove letras soltas
      if (RegExp(r'\d+').hasMatch(wordUpper)) return false; // Remove números soltos (ex: "02")
      return !_noiseWords.contains(wordUpper);
    }).toList();

    // Reconstrói a string e deixa Maiúscula
    return filteredWords.join(' ').trim().toUpperCase();
  }

  DateTime? _extractDate(String line) {
    try {
      final regex = RegExp(r'(\d{2})/(\d{2})');
      final match = regex.firstMatch(line);
      if (match != null) {
        final now = DateTime.now();
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        // Assume ano atual (Cuidado com virada de ano)
        return DateTime(now.year, month, day);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}