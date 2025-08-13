import 'dart:math';
import 'embedder.dart';

class DummyEmbedder implements IEmbedder {
  final int dimensions;

  DummyEmbedder({this.dimensions = 16});

  @override
  Future<List<double>> generate(String text) async {
    // Gera vetor "fake" com base no hash do texto (sempre igual pro mesmo texto)
    final hash = text.hashCode;
    final rand = Random(hash);
    return List.generate(dimensions, (_) => rand.nextDouble());
  }
}
