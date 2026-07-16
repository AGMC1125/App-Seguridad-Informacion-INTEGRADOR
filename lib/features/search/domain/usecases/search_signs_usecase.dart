import '../entities/sign_suggestion.dart';
import '../repositories/search_repository.dart';

/// Caso de uso: buscar señas por texto libre.
class SearchSignsUseCase {
  final SearchRepository _repository;
  const SearchSignsUseCase(this._repository);

  Future<List<SignSuggestion>> call({
    required String token,
    required String query,
  }) {
    return _repository.search(token: token, query: query);
  }
}
