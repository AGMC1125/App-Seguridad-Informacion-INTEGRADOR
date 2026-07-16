import '../entities/generation_history.dart';
import '../repositories/history_repository.dart';

/// Caso de uso: persistir un registro de generación en el historial.
class SaveHistoryUseCase {
  final HistoryRepository _repository;
  const SaveHistoryUseCase(this._repository);

  Future<GenerationHistory> call({
    required String token,
    required String originalText,
    required String avatarCode,
    String? generatedFilename,
  }) {
    return _repository.saveToHistory(
      token: token,
      originalText: originalText,
      avatarCode: avatarCode,
      generatedFilename: generatedFilename,
    );
  }
}
