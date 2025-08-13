import 'dart:convert';
import 'package:http/http.dart' as http;

class RealEmbedder {
  final String _url = 'http://127.0.0.1:5000/embed'; // URL do seu servidor Flask

  Future<List<double>> embedText(String text) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'texts': [text]}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<double>.from(data['embeddings'][0]);
    } else {
      throw Exception('Falha ao obter embedding: ${response.statusCode}');
    }
  }
}
