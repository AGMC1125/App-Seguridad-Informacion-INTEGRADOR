import '../entities/generation_history.dart';
import '../entities/history_page.dart';

/// Contrato del repositorio de historial.
///
/// La capa de dominio solo conoce este contrato. La implementación concreta
/// que realiza las llamadas HTTP vive en la capa de datos.
abstract class HistoryRepository {
  /// Obtiene una página del historial del usuario autenticado.
  /// [page] es 0-indexed.
  Future<HistoryPage> getHistory({
    required String token,
    int page = 0,
    int size = 20,
  });

  /// Persiste un nuevo registro de generación en el historial.
  Future<GenerationHistory> saveToHistory({
    required String token,
    required String originalText,
    required String avatarCode,
    String? generatedFilename,
  });

  /// Elimina un registro del historial (y su video en el servidor).
  Future<void> deleteHistoryItem({
    required String token,
    required int historyId,
  });

  /// Construye la URL absoluta para reproducir un video del historial.
  String buildVideoUrl(String relativeUrl);
}
