import '../../../../core/network/api_client.dart';
import '../../domain/entities/sign_suggestion.dart';

/// Fuente de datos remota del buscador de señas.
///
/// Responsabilidad única: ejecutar la llamada HTTP a GET /signs/search
/// y deserializar los resultados.
class SearchRemoteDataSource {
  const SearchRemoteDataSource();

  /// Busca señas relacionadas con [query].
  /// Devuelve lista vacía si el query es en blanco o si el servidor falla
  /// (las sugerencias son opcionales — fallos silenciosos).
  Future<List<SignSuggestion>> search({
    required String token,
    required String query,
  }) async {
    if (query.trim().isEmpty) return [];
    try {
      final results = await ApiClient.getList(
        '/signs/search',
        queryParams: {'q': query.trim()},
        token: token,
      );
      return results
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  SignSuggestion _fromJson(Map<String, dynamic> json) => SignSuggestion(
        word: json['word'] as String,
        video: json['video'] as String,
        score: (json['score'] as num).toDouble(),
      );
}
