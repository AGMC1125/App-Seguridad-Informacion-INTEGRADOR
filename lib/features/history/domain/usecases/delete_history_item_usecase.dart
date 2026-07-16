import '../repositories/history_repository.dart';

/// Caso de uso: eliminar un registro del historial.
class DeleteHistoryItemUseCase {
  final HistoryRepository _repository;
  const DeleteHistoryItemUseCase(this._repository);

  Future<void> call({required String token, required int historyId}) {
    return _repository.deleteHistoryItem(token: token, historyId: historyId);
  }
}
