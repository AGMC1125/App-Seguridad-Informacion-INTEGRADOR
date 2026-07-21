import '../../domain/entities/sign_suggestion.dart';

// ── Estado de la operación de búsqueda ───────────────────────────────────────

/// Ciclo de vida de la operación de búsqueda BM25.
///
/// idle → loading → success | error
enum SearchStatus {
  /// Sin búsqueda en curso (pantalla inicial o campo vacío).
  idle,

  /// Solicitud HTTP en vuelo.
  loading,

  /// Búsqueda completada. Puede haber 0 o más resultados en [SearchState.results].
  success,

  /// Búsqueda fallida. El mensaje vive en [SearchState.error].
  error,
}

// ── Estado completo de la búsqueda ───────────────────────────────────────────

/// Estado inmutable del buscador semántico BM25.
///
/// La UI lo observa vía [ref.watch] — sin lógica de negocio en el widget.
class SearchState {
  /// Estado de la última operación de búsqueda.
  final SearchStatus status;

  /// Resultados de la búsqueda. Non-empty cuando [status] == [SearchStatus.success]
  /// y la API devolvió coincidencias.
  final List<SignSuggestion> results;

  /// true si se ha ejecutado al menos una búsqueda en la sesión actual.
  final bool hasSearched;

  /// Mensaje de error. Non-null cuando [status] == [SearchStatus.error].
  final String? error;

  const SearchState({
    this.status = SearchStatus.idle,
    this.results = const [],
    this.hasSearched = false,
    this.error,
  });

  /// Estado inicial limpio.
  static const empty = SearchState();

  SearchState copyWith({
    SearchStatus? status,
    List<SignSuggestion>? results,
    bool? hasSearched,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      hasSearched: hasSearched ?? this.hasSearched,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
