import '../entities/history_page.dart';
import '../repositories/history_repository.dart';

/// Caso de uso: obtener una página del historial de generaciones.
class GetHistoryUseCase {
  final HistoryRepository _repository;
  const GetHistoryUseCase(this._repository);

  Future<HistoryPage> call({
    required String token,
    int page = 0,
    int size = 20,
  }) {
    return _repository.getHistory(token: token, page: page, size: size);
  }
}
