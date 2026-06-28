import 'api_client.dart';

/// Resultado de búsqueda semántica del endpoint GET /signs/search
class SignSuggestion {
  final String word;
  final String video;
  final double score;

  const SignSuggestion({
    required this.word,
    required this.video,
    required this.score,
  });

  factory SignSuggestion.fromJson(Map<String, dynamic> json) => SignSuggestion(
        word: json['word'] as String,
        video: json['video'] as String,
        score: (json['score'] as num).toDouble(),
      );
}

class SearchService {
  SearchService._();

  /// Busca señas del vocabulario de familia relacionadas con [query].
  /// Devuelve hasta 3 sugerencias ordenadas por relevancia (BM25).
  static Future<List<SignSuggestion>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final results = await ApiClient.getList(
        '/signs/search',
        queryParams: {'q': query.trim()},
      );
      return results
          .map((e) => SignSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return []; // Fallos silenciosos — las sugerencias son opcionales
    }
  }
}
