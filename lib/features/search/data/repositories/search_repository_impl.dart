import '../../domain/entities/sign_suggestion.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource _dataSource;
  const SearchRepositoryImpl(this._dataSource);

  @override
  Future<List<SignSuggestion>> search({
    required String token,
    required String query,
  }) {
    return _dataSource.search(token: token, query: query);
  }
}
