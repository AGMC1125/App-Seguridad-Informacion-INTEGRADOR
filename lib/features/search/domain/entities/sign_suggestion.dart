/// Entidad de dominio que representa una sugerencia de búsqueda semántica.
///
/// Devuelta por el endpoint GET /signs/search (búsqueda BM25).
class SignSuggestion {
  final String word;
  final String video;
  final double score;

  const SignSuggestion({
    required this.word,
    required this.video,
    required this.score,
  });
}
