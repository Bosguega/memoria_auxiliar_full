import 'dart:convert';
import 'package:http/http.dart' as http;


class RealEmbedder implements IEmbedder {
  final String serverUrl;

  RealEmbedder({this.serverUrl = 'http://127.0.0.1:5000/embed'});

  @override
  Future<List<double>> generate(String text) async {
    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'texts': [text]}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final embeddings = data['embeddings'] as List;
      return List<double>.from(embeddings[0]);
    } else {
      throw Exception('Falha ao gerar embedding');
    }
  }
}

abstract class IEmbedder {
  Future<List<double>> generate(String text);
}
