import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/session_notifier.dart';
import '../../../history/di/history_providers.dart';
import '../../../search/di/search_providers.dart';
import '../../di/generator_providers.dart';
import '../../domain/entities/merged_video_result.dart';
import 'generator_state.dart';

// ── GeneratorNotifier ─────────────────────────────────────────────────────────

/// Gestor de estado del generador de señas LSM.
///
/// Responsabilidad única: coordinar las operaciones de generación de video,
/// guardado en historial y búsqueda de sugerencias semánticas.
/// Delega toda lógica HTTP a los use cases correspondientes.
///
/// La UI observa [GeneratorState] vía [ref.watch] y reacciona a
/// cambios de estado vía [ref.listen] — sin lógica de negocio en el widget.
class GeneratorNotifier extends Notifier<GeneratorState> {
  @override
  GeneratorState build() => GeneratorState.empty;

  // ── Generación de video ───────────────────────────────────────────────────

  /// Genera el video fusionado LSM para el texto e avatar dados.
  ///
  /// Ciclo: idle → loading → success (con [result]) | error (con [error]).
  /// Al iniciar, limpia el resultado anterior y las sugerencias activas.
  Future<void> generateVideo({
    required String text,
    required String avatarCode,
    required String token,
  }) async {
    state = state.copyWith(
      status: GeneratorStatus.loading,
      clearResult: true,
      clearError: true,
      suggestions: const [],
      historyAlreadySaved: false,
      clearSaveHistoryError: true,
    );

    try {
      final result = await ref.read(generateMergedVideoUseCaseProvider).call(
            text: text,
            avatarCode: avatarCode,
            token: token,
          );

      if (result.mergedVideoUrl.isEmpty) {
        state = state.copyWith(
          status: GeneratorStatus.error,
          error: 'No se encontraron señas para el texto ingresado.',
          clearResult: true,
        );
        return;
      }

      state = state.copyWith(
        status: GeneratorStatus.success,
        result: result,
        clearError: true,
        historyAlreadySaved: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: GeneratorStatus.error,
        error: e.message,
        clearResult: true,
      );
    } catch (_) {
      state = state.copyWith(
        status: GeneratorStatus.error,
        error: 'No se pudo conectar con el servidor.',
        clearResult: true,
      );
    }
  }

  // ── Historial ─────────────────────────────────────────────────────────────

  /// Guarda el resultado actual en el historial del usuario.
  ///
  /// [result] debe ser el [GeneratorState.result] no nulo en el momento de la llamada.
  Future<void> saveToHistory({
    required String token,
    required MergedVideoResult result,
  }) async {
    if (state.isSavingHistory || state.historyAlreadySaved) return;

    state = state.copyWith(
      isSavingHistory: true,
      clearSaveHistoryError: true,
    );

    try {
      await ref.read(saveHistoryUseCaseProvider).call(
            token: token,
            originalText: result.originalText,
            avatarCode: result.avatarCode,
            generatedFilename: result.generatedFilename,
          );

      state = state.copyWith(
        isSavingHistory: false,
        historyAlreadySaved: true,
        clearSaveHistoryError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isSavingHistory: false,
        saveHistoryError: 'No se pudo guardar en historial',
      );
    }
  }

  // ── Sugerencias semánticas ────────────────────────────────────────────────

  /// Busca señas disponibles para la última palabra del texto en edición.
  ///
  /// [lastWord] es la última palabra (ya extraída por la UI).
  /// Si tiene menos de 2 caracteres, limpia las sugerencias sin hacer red call.
  Future<void> fetchSuggestions({
    required String lastWord,
    required String token,
  }) async {
    if (lastWord.length < 2) {
      if (state.suggestions.isNotEmpty) {
        state = state.copyWith(suggestions: const []);
      }
      return;
    }

    state = state.copyWith(loadingSuggestions: true);

    final results = await ref.read(searchSignsUseCaseProvider).call(
          token: token,
          query: lastWord,
        );

    state = state.copyWith(
      suggestions: results,
      loadingSuggestions: false,
    );
  }

  // ── Control de estado ─────────────────────────────────────────────────────

  /// Limpia el resultado, el error y las sugerencias actuales.
  ///
  /// Llamar al cambiar texto, avatar, o al iniciar una nueva generación.
  void clearResult() {
    state = state.copyWith(
      status: GeneratorStatus.idle,
      clearResult: true,
      clearError: true,
      suggestions: const [],
      historyAlreadySaved: false,
      clearSaveHistoryError: true,
    );
  }

  /// Lee el token de sesión actual desde [sessionNotifierProvider].
  String get _token => ref.read(sessionNotifierProvider).token;

  /// Shortcut: llama a [saveToHistory] usando el token de sesión activo.
  Future<void> saveCurrentResultToHistory() async {
    final result = state.result;
    if (result == null) return;
    await saveToHistory(token: _token, result: result);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Provider global del generador de señas LSM.
final generatorNotifierProvider =
    NotifierProvider<GeneratorNotifier, GeneratorState>(GeneratorNotifier.new);
