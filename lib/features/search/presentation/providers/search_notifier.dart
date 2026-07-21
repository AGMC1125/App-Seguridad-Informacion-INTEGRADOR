import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../di/search_providers.dart';
import 'search_state.dart';

// ── SearchNotifier ────────────────────────────────────────────────────────────

/// Gestor de estado del buscador semántico BM25.
///
/// Responsabilidad única: coordinar la operación de búsqueda de señas,
/// emitiendo estados idle → loading → success | error.
/// Delega toda lógica HTTP a [searchSignsUseCaseProvider].
///
/// La UI observa [SearchState] vía [ref.watch] y no contiene
/// lógica de negocio ni de red.
class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => SearchState.empty;

  // ── Búsqueda ──────────────────────────────────────────────────────────────

  /// Ejecuta una búsqueda BM25 para [query] usando el [token] de sesión activo.
  ///
  /// Si [query] está vacío, limpia los resultados y vuelve a [SearchStatus.idle].
  /// Ciclo normal: idle → loading → success | error.
  Future<void> search(String query, String token) async {
    if (query.trim().isEmpty) {
      state = SearchState.empty;
      return;
    }

    state = state.copyWith(
      status: SearchStatus.loading,
      hasSearched: true,
      clearError: true,
    );

    try {
      final results = await ref.read(searchSignsUseCaseProvider).call(
            token: token,
            query: query.trim(),
          );

      state = state.copyWith(
        status: SearchStatus.success,
        results: results,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        status: SearchStatus.error,
        results: const [],
        error: 'No se pudo realizar la búsqueda',
      );
    }
  }

  /// Limpia resultados y vuelve al estado inicial.
  void clear() {
    state = SearchState.empty;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Provider global del buscador de señas LSM.
final searchNotifierProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
