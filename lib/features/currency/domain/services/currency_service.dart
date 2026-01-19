import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const _endpoint = 'https://economia.awesomeapi.com.br/last/BTC-BRL,USD-BRL,EUR-BRL';

  Future<List<Map<String, dynamic>>> getLiveQuotes() async {
    try {
      final response = await http.get(Uri.parse(_endpoint));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return [
          {'name': 'Bitcoin', 'code': 'BTC', 'value': data['BTCBRL']['bid'], 'pct': data['BTCBRL']['pctChange']},
          {'name': 'Dólar', 'code': 'USD', 'value': data['USDBRL']['bid'], 'pct': data['USDBRL']['pctChange']},
          {'name': 'Euro', 'code': 'EUR', 'value': data['EURBRL']['bid'], 'pct': data['EURBRL']['pctChange']},
        ];
      }
      throw Exception('Erro ao acessar API de moedas');
    } catch (e) {
      rethrow;
    }
  }
}