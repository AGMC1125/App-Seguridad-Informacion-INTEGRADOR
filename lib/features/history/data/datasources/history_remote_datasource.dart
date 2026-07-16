import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/generation_history.dart';
import '../../domain/entities/history_page.dart';
import '../models/generation_history_model.dart';

/// Fuente de datos remota del historial.
///
/// Responsabilidad única: ejecutar llamadas HTTP al endpoint /history
/// y serializar/deserializar los datos. No contiene lógica de negocio.
class HistoryRemoteDataSource {
  const HistoryRemoteDataSource();

  /// Obtiene una página del historial. [page] es 0-indexed.
  Future<HistoryPage> getHistory({
    required String token,
    int page = 0,
    int size = 20,
  }) async {
    final data = await ApiClient.get(
      '/history',
      queryParams: {'page': '$page', 'size': '$size'},
      token: token,
    );

    final items = (data['content'] as List<dynamic>)
        .map((e) => GenerationHistoryModel
            .fromJson(e as Map<String, dynamic>)
            .toEntity())
        .toList();

    return HistoryPage(
      items: items,
      totalElements: data['totalElements'] as int,
      totalPages: data['totalPages'] as int,
      currentPage: data['number'] as int,
    );
  }

  /// Persiste un nuevo registro de generación en el historial.
  Future<GenerationHistory> saveToHistory({
    required String token,
    required String originalText,
    required String avatarCode,
    String? generatedFilename,
  }) async {
    final data = await ApiClient.post(
      '/history',
      {
        'originalText': originalText,
        'avatarCode': avatarCode,
        if (generatedFilename != null) 'generatedFilename': generatedFilename,
      },
      token: token,
    );
    return GenerationHistoryModel.fromJson(data).toEntity();
  }

  /// Elimina un registro del historial y su video en el servidor.
  Future<void> deleteHistoryItem({
    required String token,
    required int historyId,
  }) async {
    await ApiClient.delete('/history/$historyId', token: token);
  }

  /// Construye la URL absoluta de un video a partir de su path relativo.
  String buildVideoUrl(String relativeUrl) {
    return '${AppConstants.apiBaseUrl}$relativeUrl';
  }
}
