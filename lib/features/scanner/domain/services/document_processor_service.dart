import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';

class DocumentProcessorService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, dynamic>> processImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    return _extractData(recognizedText.text);
  }

  // Lógica de "Scraping" de texto bruto
  Map<String, dynamic> _extractData(String text) {
    // Regex para encontrar valores monetários (Ex: R$ 150,00 ou 150.00)
    final valueRegex = RegExp(r'(R\$|valor|total)\s?(\d+[\.,]\d{2})', caseSensitive: false);
    final cnpjRegex = RegExp(r'\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}');

    final matchValue = valueRegex.firstMatch(text);
    final matchCnpj = cnpjRegex.firstMatch(text);

    return {
      'valor': matchValue?.group(2) ?? "0.00",
      'cnpj': matchCnpj?.group(0) ?? "Desconhecido",
      'raw': text,
    };
  }
}