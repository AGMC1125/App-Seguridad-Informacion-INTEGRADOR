import '../constants/app_constants.dart';
import '../../features/history/models/generation_history.dart';
import 'api_client.dart';

class HistoryPage {
  final List<GenerationHistory> items;
  final int totalElements;
  final int totalPages;
  final int currentPage;

  const HistoryPage({
    required this.items,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
  });
}

class HistoryService {
  HistoryService._();

  /// Obtiene el historial paginado del usuario. [page] es 0-indexed.
  static Future<HistoryPage> getHistory({
    required String token,
    int page = 0,
    int size = 20,
  }) async {
    final data = await ApiClient.get(
      '/history',
      queryParams: {'page': '$page', 'size': '$size'},
      token: token,
    );

    final content = (data['content'] as List<dynamic>)
        .map((e) => GenerationHistory.fromJson(e as Map<String, dynamic>))
        .toList();

    return HistoryPage(
      items: content,
      totalElements: data['totalElements'] as int,
      totalPages: data['totalPages'] as int,
      currentPage: data['number'] as int,
    );
  }

  /// Guarda una generación en el historial.
  static Future<GenerationHistory> saveToHistory({
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
    return GenerationHistory.fromJson(data);
  }

  /// Elimina un item del historial (y su video en el servidor).
  static Future<void> deleteHistory({
    required String token,
    required int historyId,
  }) async {
    await ApiClient.delete('/history/$historyId', token: token);
  }

  /// Construye la URL absoluta para reproducir/descargar el video.
  static String buildVideoUrl(String relativeUrl) {
    return '${AppConstants.apiBaseUrl}$relativeUrl';
  }
}
