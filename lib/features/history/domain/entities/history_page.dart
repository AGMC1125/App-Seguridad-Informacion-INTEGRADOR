import 'generation_history.dart';

/// Value object que encapsula una página de resultados del historial.
///
/// Refleja la estructura paginada que devuelve la API (Spring Boot Page<T>).
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
