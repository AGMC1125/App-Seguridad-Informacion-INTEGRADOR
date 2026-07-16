import '../entities/sign_suggestion.dart';

/// Contrato del repositorio de búsqueda de señas.
abstract class SearchRepository {
  /// Busca señas del vocabulario relacionadas con [query].
  /// Devuelve hasta 3 sugerencias ordenadas por relevancia (BM25).
  /// Devuelve lista vacía si [query] está en blanco o ocurre un error.
  Future<List<SignSuggestion>> search({
    required String token,
    required String query,
  });
}
