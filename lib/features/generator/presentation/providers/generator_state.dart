import '../../domain/entities/merged_video_result.dart';
import '../../../search/domain/entities/sign_suggestion.dart';

// ── Estado de la operación de generación ─────────────────────────────────────

/// Ciclo de vida de la operación de generación de video LSM.
///
/// idle → loading → success | error
enum GeneratorStatus {
  /// Sin operación en curso.
  idle,

  /// Solicitud HTTP en vuelo.
  loading,

  /// Video generado exitosamente.
  success,

  /// Operación fallida. El mensaje vive en [GeneratorState.error].
  error,
}

// ── Estado completo del generador ─────────────────────────────────────────────

/// Estado inmutable del generador de señas LSM.
///
/// Encapsula el ciclo de vida de la generación, el resultado del video,
/// el estado del historial y las sugerencias semánticas.
/// La UI lo observa vía [ref.watch] y reacciona a cambios vía [ref.listen].
class GeneratorState {
  /// Estado de la última operación de generación.
  final GeneratorStatus status;

  /// Resultado del video fusionado. Non-null cuando [status] == [GeneratorStatus.success].
  final MergedVideoResult? result;

  /// Mensaje de error. Non-null cuando [status] == [GeneratorStatus.error].
  final String? error;

  // ── Historial ─────────────────────────────────────────────────────────────

  /// true mientras la llamada de guardado en historial está en vuelo.
  final bool isSavingHistory;

  /// true cuando el resultado actual ya fue guardado en historial.
  final bool historyAlreadySaved;

  /// Mensaje de error al guardar en historial (null si éxito o no intentado).
  final String? saveHistoryError;

  // ── Sugerencias semánticas ────────────────────────────────────────────────

  /// Resultados de la búsqueda semántica BM25 en tiempo real.
  final List<SignSuggestion> suggestions;

  /// true mientras la búsqueda de sugerencias está en vuelo.
  final bool loadingSuggestions;

  const GeneratorState({
    this.status = GeneratorStatus.idle,
    this.result,
    this.error,
    this.isSavingHistory = false,
    this.historyAlreadySaved = false,
    this.saveHistoryError,
    this.suggestions = const [],
    this.loadingSuggestions = false,
  });

  /// Estado inicial limpio.
  static const empty = GeneratorState();

  GeneratorState copyWith({
    GeneratorStatus? status,
    MergedVideoResult? result,
    bool clearResult = false,
    String? error,
    bool clearError = false,
    bool? isSavingHistory,
    bool? historyAlreadySaved,
    String? saveHistoryError,
    bool clearSaveHistoryError = false,
    List<SignSuggestion>? suggestions,
    bool? loadingSuggestions,
  }) {
    return GeneratorState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      isSavingHistory: isSavingHistory ?? this.isSavingHistory,
      historyAlreadySaved: historyAlreadySaved ?? this.historyAlreadySaved,
      saveHistoryError: clearSaveHistoryError
          ? null
          : (saveHistoryError ?? this.saveHistoryError),
      suggestions: suggestions ?? this.suggestions,
      loadingSuggestions: loadingSuggestions ?? this.loadingSuggestions,
    );
  }
}
