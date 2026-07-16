import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/session_notifier.dart';
import '../../../dictionary/presentation/word_detail_screen.dart';
import '../../di/search_providers.dart';
import '../providers/search_notifier.dart';
import '../providers/search_state.dart';

// ---------------------------------------------------------------------------
// SearchScreen — buscador semántico BM25
// ---------------------------------------------------------------------------

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  // ── Estado local puro de UI ────────────────────────────────────────────────
  // El estado de búsqueda (results, loading, hasSearched) vive en SearchNotifier.
  // Solo se mantiene aquí el controlador del campo de texto — ciclo de vida del widget.
  final _searchController = TextEditingController();

  static const _allFamilyWords = [
    'abuelo', 'abuela', 'papa', 'mama',
    'hijo', 'hija', 'hermano', 'hermana',
    'tio', 'tia', 'primo', 'prima',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    // Limpiar estado del notifier al salir de la pantalla
    ref.read(searchNotifierProvider.notifier).clear();
    super.dispose();
  }

  void _navigateToWord(String word) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => WordDetailScreen(word: word)));
  }

  @override
  Widget build(BuildContext context) {
    // ── Observar estado del notifier ──────────────────────────────────────
    final searchState = ref.watch(searchNotifierProvider);
    final isLoading = searchState.status == SearchStatus.loading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Buscador', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
        backgroundColor: context.cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.dividerColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search field ───────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.dividerColor),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 15, color: context.textPrimary),
                textInputAction: TextInputAction.search,
                onChanged: (query) {
                  final token = ref.read(sessionNotifierProvider).token;
                  ref.read(searchNotifierProvider.notifier).search(query, token);
                  // Forzar rebuild del suffixIcon (que depende del texto del controlador)
                  setState(() {});
                },
                onSubmitted: (query) {
                  final token = ref.read(sessionNotifierProvider).token;
                  ref.read(searchNotifierProvider.notifier).search(query, token);
                },
                decoration: InputDecoration(
                  hintText: 'Busca una seña… ej: padre, madre',
                  hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.5), fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: context.textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchNotifierProvider.notifier).clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // BM25 info badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 11, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text('Motor BM25 · Búsqueda semántica en español',
                          style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Results ────────────────────────────────────────────────────
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (searchState.hasSearched && searchState.results.isNotEmpty) ...[
              Text('Resultados', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary)),
              const SizedBox(height: 12),
              ...searchState.results.map((r) => _buildResultCard(context, r, searchState)),
              const SizedBox(height: 8),
            ]
            else if (searchState.hasSearched && searchState.results.isEmpty) ...[
              _buildNoResultsBanner(context),
              const SizedBox(height: 24),
            ],

            _buildSuggestionSection(context, searchState),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  double _normalizeScore(double score, SearchState searchState) {
    if (searchState.results.isEmpty) return 0;
    final maxScore = searchState.results.map((r) => r.score).reduce((a, b) => a > b ? a : b);
    if (maxScore == 0) return 0;
    return (score / maxScore).clamp(0.0, 1.0);
  }

  Color _barColor(double normalized) {
    if (normalized >= 0.75) return AppColors.accent;
    if (normalized >= 0.45) return AppColors.primary;
    return AppColors.warning;
  }

  Widget _buildResultCard(BuildContext context, result, SearchState searchState) {
    final score = (result.score * 100).round();
    final normalized = _normalizeScore(result.score, searchState);
    final barColor = _barColor(normalized);

    return GestureDetector(
      onTap: () => _navigateToWord(result.word),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_capitalize(result.word),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Vocabulario de familia · LSM',
                          style: TextStyle(fontSize: 11, color: context.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: barColor.withOpacity(0.35)),
                      ),
                      child: Text('$score% relevancia',
                          style: TextStyle(fontSize: 10, color: barColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textSecondary),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Similitud BM25', style: TextStyle(fontSize: 10, color: context.textSecondary)),
                const Spacer(),
                Text('${(normalized * 100).round()}%',
                    style: TextStyle(fontSize: 10, color: barColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(height: 7, width: double.infinity, color: barColor.withOpacity(0.12)),
                  FractionallySizedBox(
                    widthFactor: normalized,
                    child: Container(
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: normalized >= 0.75
                              ? [AppColors.primary, AppColors.accent]
                              : normalized >= 0.45
                                  ? [AppColors.primary, AppColors.primary.withOpacity(0.6)]
                                  : [AppColors.warning, AppColors.warning.withOpacity(0.6)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 42, color: context.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 10),
          Text('No se encontraron resultados similares',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            'El motor BM25 no encontró coincidencias para "${_searchController.text}".\nIntenta con términos relacionados como "padre", "madre" o "hijo".',
            style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionSection(BuildContext context, SearchState searchState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              searchState.hasSearched && searchState.results.isEmpty
                  ? 'Tal vez te pueda interesar…'
                  : 'Todo el vocabulario disponible',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Palabras disponibles en el diccionario de familia',
            style: TextStyle(fontSize: 12, color: context.textSecondary)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allFamilyWords.map((word) => GestureDetector(
            onTap: () => _navigateToWord(word),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sign_language_rounded, size: 13, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(_capitalize(word),
                      style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
