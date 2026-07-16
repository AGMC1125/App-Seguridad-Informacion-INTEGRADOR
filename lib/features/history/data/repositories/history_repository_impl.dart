import '../../domain/entities/generation_history.dart';
import '../../domain/entities/history_page.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_datasource.dart';

/// Implementación concreta del [HistoryRepository].
///
/// Coordina entre el datasource remoto y las entidades de dominio.
class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource _dataSource;
  const HistoryRepositoryImpl(this._dataSource);

  @override
  Future<HistoryPage> getHistory({
    required String token,
    int page = 0,
    int size = 20,
  }) {
    return _dataSource.getHistory(token: token, page: page, size: size);
  }

  @override
  Future<GenerationHistory> saveToHistory({
    required String token,
    required String originalText,
    required String avatarCode,
    String? generatedFilename,
  }) {
    return _dataSource.saveToHistory(
      token: token,
      originalText: originalText,
      avatarCode: avatarCode,
      generatedFilename: generatedFilename,
    );
  }

  @override
  Future<void> deleteHistoryItem({
    required String token,
    required int historyId,
  }) {
    return _dataSource.deleteHistoryItem(token: token, historyId: historyId);
  }

  @override
  String buildVideoUrl(String relativeUrl) {
    return _dataSource.buildVideoUrl(relativeUrl);
  }
}
