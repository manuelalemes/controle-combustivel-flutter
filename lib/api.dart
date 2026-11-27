import 'dart:convert';
import 'package:http/http.dart' as http;

class Brand {
  final String name, code;
  Brand(this.name, this.code);
}

/// BrasilAPI - FIPE: https://brasilapi.com.br/docs#tag/FIPE
class BrasilApi {
  static const _base = 'https://brasilapi.com.br/api/fipe';

  static Future<List> _get(String path) async {
    final r = await http.get(Uri.parse('$_base/$path')).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw Exception('Erro ${r.statusCode} ao consultar a API');
    return jsonDecode(utf8.decode(r.bodyBytes)) as List;
  }

  static Future<List<Brand>> brands() async {
    final l = await _get('marcas/v1/carros');
    return l.map((e) => Brand(e['nome'].toString(), e['valor'].toString())).toList();
  }

  static Future<List<String>> models(String brandCode) async {
    final l = await _get('veiculos/v1/carros/$brandCode');
    return l.map((e) => e['modelo'].toString()).toSet().toList()..sort();
  }
}
