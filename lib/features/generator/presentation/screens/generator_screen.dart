import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/auth/presentation/providers/session_notifier.dart';
import '../../../../theme/app_theme.dart';
import '../../di/generator_providers.dart';
import '../../domain/entities/merged_video_result.dart';
import '../providers/generator_notifier.dart';
import '../providers/generator_state.dart';

// ---------------------------------------------------------------------------
// Modelo de avatar (privado, solo presentation)
// ---------------------------------------------------------------------------

class _AvatarOption {
  final String id;
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const _AvatarOption({
    required this.id,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// GeneratorScreen — texto → señas LSM (video fusionado)
// ---------------------------------------------------------------------------

class GeneratorScreen extends ConsumerStatefulWidget {
  const GeneratorScreen({super.key});

  @override
  ConsumerState<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends ConsumerState<GeneratorScreen> {
  // ── Estado local puro de UI (no pertenece al dominio) ─────────────────────
  int? _selectedAvatarIndex;
  final _textController = TextEditingController();

  // ── Video player (ciclo de vida ligado al widget) ─────────────────────────
  VideoPlayerController? _videoController;
  bool _videoLoading = false;

  // ── Compartir / descargar (acción de infraestructura de plataforma) ────────
  bool _isSharing = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();

  static const List<_AvatarOption> _avatars = [
    _AvatarOption(
      id: 'nino',
      icon: Icons.boy_rounded,
      label: 'Niño',
      description: 'Avatar infantil masculino',
      color: Color(0xFF2563EB),
    ),
    _AvatarOption(
      id: 'nina',
      icon: Icons.girl_rounded,
      label: 'Niña',
      description: 'Avatar infantil femenino',
      color: Color(0xFFDB2777),
    ),
    _AvatarOption(
      id: 'hombre_adulto',
      icon: Icons.man_rounded,
      label: 'Hombre adulto',
      description: 'Avatar adulto masculino',
      color: Color(0xFF059669),
    ),
    _AvatarOption(
      id: 'mujer_adulta',
      icon: Icons.woman_rounded,
      label: 'Mujer adulta',
      description: 'Avatar adulto femenino',
      color: Color(0xFF7C3AED),
    ),
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _disposeVideoController();
    // Limpiar estado del notifier para evitar residuos al volver a la pantalla
    ref.read(generatorNotifierProvider.notifier).clearResult();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Video player helpers — ciclo de vida ligado al widget
  // ---------------------------------------------------------------------------

  Future<void> _loadVideo(MergedVideoResult result) async {
    setState(() => _videoLoading = true);
    await _disposeVideoController();
    final url = '${AppConstants.apiBaseUrl}${result.mergedVideoUrl}';
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      controller.addListener(_onVideoProgress);
      if (!mounted) { controller.dispose(); return; }
      setState(() {
        _videoController = controller;
        _videoLoading = false;
      });
      controller.play();
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _videoLoading = false);
    }
  }

  void _onVideoProgress() {
    // El video fusionado se detiene en el último frame al terminar.
  }

  Future<void> _disposeVideoController() async {
    final old = _videoController;
    _videoController = null;
    old?.removeListener(_onVideoProgress);
    await old?.dispose();
  }

  // ---------------------------------------------------------------------------
  // Generar señas — delega al GeneratorNotifier
  // ---------------------------------------------------------------------------

  Future<void> _onGenerate() async {
    final avatar = _avatars[_selectedAvatarIndex!];
    final text = _textController.text.trim();
    final token = ref.read(sessionNotifierProvider).token;

    await _disposeVideoController();

    await ref.read(generatorNotifierProvider.notifier).generateVideo(
          text: text,
          avatarCode: avatar.id,
          token: token,
        );
  }

  // ---------------------------------------------------------------------------
  // Acciones de plataforma: descargar y compartir
  // (no involucran lógica de dominio — permanecen en el widget)
  // ---------------------------------------------------------------------------

  Future<void> _downloadVideo(MergedVideoResult result) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final url = '${AppConstants.apiBaseUrl}${result.mergedVideoUrl}';
      final response = await http.get(Uri.parse(url));
      final Directory dir;
      if (Platform.isAndroid) {
        dir = (await getExternalStorageDirectory())!;
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      final filename = result.generatedFilename.isNotEmpty
          ? result.generatedFilename
          : 'sena_lsm_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);
      if (!mounted) return;
      setState(() => _isSharing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Video guardado: $filename'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSharing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al descargar el video'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _shareViaWhatsApp(MergedVideoResult result) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final url = '${AppConstants.apiBaseUrl}${result.mergedVideoUrl}';
      final response = await http.get(Uri.parse(url));
      final tmpDir = await getTemporaryDirectory();
      final filename = result.generatedFilename.isNotEmpty
          ? result.generatedFilename
          : 'sena_lsm_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File('${tmpDir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'video/mp4')],
        text: 'Seña LSM: "${result.originalText}"',
      );
      if (mounted) setState(() => _isSharing = false);
    } catch (_) {
      if (mounted) {
        setState(() => _isSharing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al compartir el video'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // ── Observar estado del notifier ──────────────────────────────────────
    final genState = ref.watch(generatorNotifierProvider);
    final isGenerating = genState.status == GeneratorStatus.loading;

    // ── Efectos secundarios: reaccionar a cambios de estado ───────────────
    ref.listen<GeneratorState>(generatorNotifierProvider, (prev, next) {
      // Cuando llega un resultado nuevo → cargar video + scroll automático
      if (next.result != null && next.result != prev?.result) {
        _loadVideo(next.result!);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOutCubic,
            );
          }
        });
      }

      // Historial guardado exitosamente
      if (!(prev?.historyAlreadySaved ?? false) && next.historyAlreadySaved) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Guardado en historial'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }

      // Error al guardar en historial
      if (next.saveHistoryError != null &&
          next.saveHistoryError != prev?.saveHistoryError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.saveHistoryError!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.dark : AppGradients.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Generador de Señas',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(color: Colors.transparent),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: isDark ? const Color(0x22FFFFFF) : const Color(0x22000000)),
          ),
        ),
        body: Stack(
          children: [
            Positioned(
              top: -40, right: -40,
              child: AppBlob(size: 220, color: AppColors.primary, opacity: isDark ? 0.09 : 0.07),
            ),
            Positioned(
              bottom: 80, left: -40,
              child: AppBlob(size: 180, color: AppColors.violet, opacity: isDark ? 0.07 : 0.05),
            ),
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Info banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'El texto será deletreado letra por letra en Lengua de Señas Mexicana',
                            style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Paso 1: Avatar
                  _buildStepLabel(context, '1', 'Selecciona un avatar'),
                  const SizedBox(height: 4),
                  Text('El avatar representará las señas en la animación generada',
                      style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  const SizedBox(height: 14),
                  _buildAvatarGrid(context, genState),
                  const SizedBox(height: 26),

                  // Paso 2: Texto
                  _buildStepLabel(context, '2', 'Escribe el texto'),
                  const SizedBox(height: 4),
                  Text('El texto será deletreado letra a letra en LSM',
                      style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  const SizedBox(height: 14),
                  _buildTextInput(context, genState),
                  const SizedBox(height: 10),
                  _buildSuggestions(context, genState),
                  _buildExampleChips(context),
                  const SizedBox(height: 22),

                  if (genState.error != null) ...[
                    _buildErrorBanner(genState.error!),
                    const SizedBox(height: 16),
                  ],

                  _buildGenerateButton(context, isGenerating),

                  if (genState.result != null) ...[
                    const SizedBox(height: 32),
                    KeyedSubtree(
                      key: _resultKey,
                      child: _buildStepLabel(context, '3', 'Reproducción de señas'),
                    ),
                    const SizedBox(height: 14),
                    _buildResultCard(context, genState),
                  ],

                  const SizedBox(height: 36),
                ],
              ),
            ),

            // Overlay de carga al generar
            if (isGenerating)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: (isDark ? Colors.black : Colors.white).withOpacity(0.45),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: context.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.18),
                              blurRadius: 40,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 56, height: 56,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 3.5,
                                backgroundColor: AppColors.primary.withOpacity(0.12),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Generando señas',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Procesando el video en LSM…',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step label
  // ---------------------------------------------------------------------------

  Widget _buildStepLabel(BuildContext context, String number, String title) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
            borderRadius: BorderRadius.circular(9),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.30), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Center(child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Avatar grid
  // ---------------------------------------------------------------------------

  Widget _buildAvatarGrid(BuildContext context, GeneratorState genState) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15,
      ),
      itemCount: _avatars.length,
      itemBuilder: (_, index) => _buildAvatarCard(context, index, genState),
    );
  }

  Widget _buildAvatarCard(BuildContext context, int index, GeneratorState genState) {
    final avatar = _avatars[index];
    final isSelected = _selectedAvatarIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedAvatarIndex = index);
        if (genState.result != null || genState.error != null) {
          ref.read(generatorNotifierProvider.notifier).clearResult();
          _disposeVideoController();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? avatar.color.withOpacity(context.isDark ? 0.15 : 0.08) : context.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? avatar.color : context.dividerColor, width: isSelected ? 2.0 : 1.0),
          boxShadow: isSelected
              ? [BoxShadow(color: avatar.color.withOpacity(0.22), blurRadius: 14, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    color: avatar.color.withOpacity(isSelected ? 0.18 : 0.10),
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: avatar.color.withOpacity(0.4), width: 2) : null,
                  ),
                  child: Icon(avatar.icon, color: avatar.color, size: 34),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: avatar.color, shape: BoxShape.circle,
                      border: const Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
                    ),
                    child: const Icon(Icons.check, size: 11, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(avatar.label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: isSelected ? avatar.color : context.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(avatar.description,
                style: TextStyle(fontSize: 10, color: context.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Text input
  // ---------------------------------------------------------------------------

  Widget _buildTextInput(BuildContext context, GeneratorState genState) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _textController,
        maxLines: 3,
        maxLength: 200,
        style: TextStyle(fontSize: 14, color: context.textPrimary),
        decoration: InputDecoration(
          hintText: 'Ej: Hola, que tal?',
          hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.5), fontSize: 14),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          counterStyle: TextStyle(color: context.textSecondary, fontSize: 11),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10, top: 14),
            child: Icon(Icons.text_fields_rounded, color: AppColors.primary, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
        ),
        onChanged: (value) {
          // Limpia resultado anterior al editar texto
          if (genState.result != null || genState.error != null) {
            ref.read(generatorNotifierProvider.notifier).clearResult();
          }
          final token = ref.read(sessionNotifierProvider).token;
          final lastWord = value.trim().split(' ').last;
          ref.read(generatorNotifierProvider.notifier).fetchSuggestions(
                lastWord: lastWord,
                token: token,
              );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sugerencias semánticas — observa GeneratorState.suggestions
  // ---------------------------------------------------------------------------

  Widget _buildSuggestions(BuildContext context, GeneratorState genState) {
    if (genState.loadingSuggestions) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary)),
            const SizedBox(width: 8),
            Text('Buscando señas…', style: TextStyle(fontSize: 11, color: context.textSecondary)),
          ],
        ),
      );
    }
    if (genState.suggestions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.accent),
              const SizedBox(width: 5),
              Text('Señas disponibles para esta palabra:',
                  style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: genState.suggestions.map((s) => GestureDetector(
              onTap: () {
                final parts = _textController.text.trim().split(' ');
                parts[parts.length - 1] = s.word;
                _textController.text = '${parts.join(' ')} ';
                _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
                ref.read(generatorNotifierProvider.notifier).clearResult();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sign_language_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(s.word, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Example chips
  // ---------------------------------------------------------------------------

  Widget _buildExampleChips(BuildContext context) {
    final examples = ['Hola', 'Buenos dias', 'Como estas'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ejemplos rápidos:', style: TextStyle(fontSize: 11, color: context.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8, runSpacing: 6,
          children: examples.map((e) => GestureDetector(
            onTap: () {
              _textController.text = e;
              ref.read(generatorNotifierProvider.notifier).clearResult();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.primaryContainerColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Text(e, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          )).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Error banner
  // ---------------------------------------------------------------------------

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.error, height: 1.4))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Generate button
  // ---------------------------------------------------------------------------

  Widget _buildGenerateButton(BuildContext context, bool isGenerating) {
    final canGenerate = _selectedAvatarIndex != null && _textController.text.trim().isNotEmpty;
    return SizedBox(
      width: double.infinity, height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: canGenerate ? const LinearGradient(colors: [AppColors.primary, AppColors.accent]) : null,
          color: canGenerate ? null : context.dividerColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: canGenerate
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.38), blurRadius: 20, offset: const Offset(0, 6))]
              : [],
        ),
        child: ElevatedButton.icon(
          onPressed: canGenerate && !isGenerating ? _onGenerate : null,
          icon: isGenerating
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Icon(Icons.play_circle_filled_rounded, size: 24),
          label: Text(isGenerating ? 'Generando…' : 'Generar en LSM',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white, disabledForegroundColor: context.textSecondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Result card
  // ---------------------------------------------------------------------------

  Widget _buildResultCard(BuildContext context, GeneratorState genState) {
    final result = genState.result!;
    final avatar = _avatars[_selectedAvatarIndex!];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardColor, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(width: double.infinity, height: 240, child: _buildVideoPlayer(avatar)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVideoInfo(context, result),
                const SizedBox(height: 12),
                _buildVideoControls(context),
                const SizedBox(height: 12),
                _buildActionButtons(context, genState, result),
                const SizedBox(height: 14),
                _buildTextTokens(context, result),
                if (result.unsupportedCharacters.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildUnsupportedChips(result.unsupportedCharacters),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      _disposeVideoController();
                      ref.read(generatorNotifierProvider.notifier).clearResult();
                      _textController.clear();
                      setState(() => _selectedAvatarIndex = null);
                    },
                    icon: Icon(Icons.refresh_rounded, size: 16, color: context.textSecondary),
                    label: Text('Nueva generación', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                    style: TextButton.styleFrom(foregroundColor: context.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Text tokens & unsupported chars
  // ---------------------------------------------------------------------------

  Widget _buildTextTokens(BuildContext context, MergedVideoResult result) {
    final tokens = result.originalText.trim().split(' ').where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Palabras generadas',
            style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: tokens.map((t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sign_language_rounded, size: 11, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(t.toUpperCase(),
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildUnsupportedChips(List<String> chars) {
    return Builder(builder: (context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Caracteres no disponibles en LSM',
              style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: chars.map((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.warning.withOpacity(0.30)),
              ),
              child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ],
      );
    });
  }

  Widget _buildVideoPlayer(_AvatarOption avatar) {
    if (_videoLoading) {
      return Container(color: const Color(0xFF0F172A), child: const Center(child: CircularProgressIndicator(color: Colors.white54)));
    }
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: const Color(0xFF0F172A),
        child: Center(child: Icon(avatar.icon, color: avatar.color.withOpacity(0.6), size: 72)),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(color: Colors.black),
        Center(child: AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller))),
        Positioned(
          bottom: 10, right: 14,
          child: ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, value, __) {
              final isPlaying = value.isPlaying;
              return GestureDetector(
                onTap: () => isPlaying ? controller.pause() : controller.play(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 22),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoInfo(BuildContext context, MergedVideoResult result) {
    final charCount = result.originalText.replaceAll(' ', '').length;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_file_rounded, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text('Video fusionado',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text('$charCount letras', style: TextStyle(fontSize: 13, color: context.textSecondary)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
            const SizedBox(width: 4),
            const Text('Listo', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
          ]),
        ),
      ],
    );
  }

  Widget _buildVideoControls(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: !_videoLoading ? const LinearGradient(colors: [AppColors.primary, AppColors.accent]) : null,
              color: _videoLoading ? context.dividerColor : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: !_videoLoading && _videoController != null
                  ? () async {
                      await _videoController?.seekTo(Duration.zero);
                      _videoController?.play();
                    }
                  : null,
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('Repetir video', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white, disabledForegroundColor: context.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, GeneratorState genState, MergedVideoResult result) {
    return Row(
      children: [
        _buildActionChip(
          context,
          icon: genState.historyAlreadySaved
              ? Icons.bookmark_rounded
              : (genState.isSavingHistory ? null : Icons.bookmark_add_outlined),
          label: genState.historyAlreadySaved ? 'En historial' : 'Historial',
          color: genState.historyAlreadySaved ? AppColors.success : AppColors.primary,
          loading: genState.isSavingHistory,
          onTap: (genState.isSavingHistory || genState.historyAlreadySaved)
              ? null
              : () => ref.read(generatorNotifierProvider.notifier).saveCurrentResultToHistory(),
        ),
        const SizedBox(width: 8),
        _buildActionChip(
          context,
          icon: _isSharing ? null : Icons.share_rounded,
          label: 'Compartir',
          color: AppColors.accent,
          loading: _isSharing,
          onTap: _isSharing ? null : () => _shareViaWhatsApp(result),
        ),
        const SizedBox(width: 8),
        _buildActionChip(
          context,
          icon: Icons.download_rounded,
          label: 'Descargar',
          color: AppColors.primary,
          loading: false,
          onTap: () => _downloadVideo(result),
        ),
      ],
    );
  }

  Widget _buildActionChip(
    BuildContext context, {
    required IconData? icon,
    required String label,
    required Color color,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(onTap != null ? 0.10 : 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(onTap != null ? 0.25 : 0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: color))
              else if (icon != null)
                Icon(icon, size: 14, color: onTap != null ? color : context.textSecondary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: onTap != null ? color : context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
