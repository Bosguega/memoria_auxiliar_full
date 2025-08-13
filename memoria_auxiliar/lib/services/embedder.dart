abstract class IEmbedder {
  Future<List<double>> generate(String text);
}

abstract class IReranker {
  Future<List<String>> rerank(String query, List<String> candidates);
}
