import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/session_notifier.dart';
import '../../domain/entities/generation_history.dart';
import '../../di/history_providers.dart';

// ── Estado ────────────────────────────────────────────────────────────────────

/// Estado inmutable del historial de generaciones.
class HistoryState {
  final List<GenerationHistory> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalPages;

  const HistoryState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 0,
    this.totalPages = 1,
  });

  bool get hasMore => currentPage + 1 < totalPages;

  HistoryState copyWith({
    List<GenerationHistory>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    int? currentPage,
    int? totalPages,
  }) {
    return HistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Gestor del estado del historial.
///
/// Responsabilidad única: coordinar las operaciones del historial
/// (carga paginada, guardado, eliminación) delegando a los use cases.
class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() => const HistoryState();

  String get _token => ref.read(sessionNotifierProvider).token;

  /// Carga la primera página del historial.
  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true, currentPage: 0);
    try {
      final page = await ref
          .read(getHistoryUseCaseProvider)
          .call(token: _token, page: 0);
      state = state.copyWith(
        items: page.items,
        isLoading: false,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Carga la siguiente página y la añade a la lista existente (infinite scroll).
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final page = await ref
          .read(getHistoryUseCaseProvider)
          .call(token: _token, page: nextPage);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        isLoadingMore: false,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Elimina un registro del historial por ID.
  Future<void> deleteItem(int historyId) async {
    try {
      await ref
          .read(deleteHistoryItemUseCaseProvider)
          .call(token: _token, historyId: historyId);
      state = state.copyWith(
        items: state.items.where((i) => i.id != historyId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Persiste una generación en el historial tras una generación exitosa.
  Future<GenerationHistory?> saveItem({
    required String originalText,
    required String avatarCode,
    String? generatedFilename,
  }) async {
    try {
      final item = await ref.read(saveHistoryUseCaseProvider).call(
            token: _token,
            originalText: originalText,
            avatarCode: avatarCode,
            generatedFilename: generatedFilename,
          );
      state = state.copyWith(items: [item, ...state.items]);
      return item;
    } catch (_) {
      return null;
    }
  }

  /// Construye la URL absoluta de reproducción de un video del historial.
  String buildVideoUrl(String relativeUrl) {
    return ref.read(historyRepositoryProvider).buildVideoUrl(relativeUrl);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final historyNotifierProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);
