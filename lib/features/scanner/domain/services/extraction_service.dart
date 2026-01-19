import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../features/dashboard/data/models/transaction_model.dart';

class ExtractionService {
  // URL do seu backend de Scraping no Fedora ou servidor
  static const _apiUrl = 'https://sua-api-scraping.com/v1/extract';

  Future<TransactionModel> uploadAndExtract(File imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Mapeia o JSON da sua API direto para o TransactionModel do Isar
      return TransactionModel()
        ..title = data['merchant_name'] ?? 'Compra Digitalizada'
        ..value = (data['total_amount'] as num).toDouble()
        ..date = DateTime.tryParse(data['date']) ?? DateTime.now()
        ..category = data['category'] ?? 'Geral'
        ..type = 'expense'
        ..cnpjEstabelecimento = data['cnpj']
        ..rawText = data['full_ocr_text'];
    } else {
      throw Exception('Falha no processamento da Nota Fiscal');
    }
  }
}