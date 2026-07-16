import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/generation_history.dart';
import '../providers/history_notifier.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  // ── UI state (no pertenece al notifier) ────────────────────────────────────
  VideoPlayerController? _videoController;
  int? _playingId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Carga inicial delegada al notifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyNotifierProvider.notifier).loadHistory();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _disposeVideo();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await _disposeVideo();
    setState(() => _playingId = null);
    await ref.read(historyNotifierProvider.notifier).loadHistory();
  }

  Future<void> _delete(GenerationHistory item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar del historial',
            style: TextStyle(color: ctx.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Eliminar "${item.originalText}"?\nEsto también borrará el video del servidor.',
          style: TextStyle(color: ctx.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: ctx.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    if (_playingId == item.id) await _disposeVideo();

    await ref.read(historyNotifierProvider.notifier).deleteItem(item.id);
    if (mounted) _showSnack('Eliminado del historial', AppColors.success);
  }

  Future<void> _shareVideo(GenerationHistory item) async {
    if (item.mergedVideoUrl == null) return;
    final url = ref
        .read(historyNotifierProvider.notifier)
        .buildVideoUrl(item.mergedVideoUrl!);

    try {
      _showSnack('Descargando video para compartir…', AppColors.primary);
      final response = await http.get(Uri.parse(url));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${item.generatedFilename ?? 'video.mp4'}');
      await file.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'video/mp4')],
        text: 'Señas LSM: ${item.originalText}',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('No se pudo compartir el video', AppColors.error);
    }
  }

  Future<void> _togglePlay(GenerationHistory item) async {
    if (item.mergedVideoUrl == null) return;

    if (_playingId == item.id) {
      await _disposeVideo();
      return;
    }

    await _disposeVideo();
    final url = ref
        .read(historyNotifierProvider.notifier)
        .buildVideoUrl(item.mergedVideoUrl!);
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await controller.initialize();
      if (!mounted) { controller.dispose(); return; }
      setState(() {
        _videoController = controller;
        _playingId = item.id;
      });
      await controller.play();
    } catch (_) {
      controller.dispose();
      if (mounted) _showSnack('No se pudo reproducir el video', AppColors.error);
    }
  }

  Future<void> _disposeVideo() async {
    final old = _videoController;
    _videoController = null;
    if (mounted) setState(() => _playingId = null);
    await old?.dispose();
  }

  String _avatarLabel(String code) {
    const labels = <String, String>{
      'nino':          'Niño',
      'nina':          'Niña',
      'hombre_adulto': 'Hombre adulto',
      'mujer_adulta':  'Mujer adulta',
    };
    return labels[code] ?? code.replaceAll('_', ' ');
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyNotifierProvider);
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
          title: Text('Historial',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                color: isDark
                    ? Colors.black.withOpacity(0.22)
                    : Colors.white.withOpacity(0.60),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: context.textSecondary, size: 22),
              tooltip: 'Actualizar',
              onPressed: _refresh,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : AppColors.lightDivider.withOpacity(0.6),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: _buildBody(context, historyState),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HistoryState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: context.textSecondary, size: 48),
              const SizedBox(height: 16),
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _refresh,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history_rounded, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text('Sin historial aún',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Los videos generados aparecerán aquí',
                      style: TextStyle(fontSize: 13, color: context.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: state.items.length + (state.isLoadingMore || state.hasMore ? 1 : 0),
      itemBuilder: (ctx, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
          );
        }
        return _buildCard(context, state.items[index]);
      },
    );
  }

  Widget _buildCard(BuildContext context, GenerationHistory item) {
    final isPlaying = _playingId == item.id;
    final hasVideo = item.mergedVideoUrl != null;
    final isDark = context.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.07 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_rounded, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          _avatarLabel(item.avatarCode),
                          style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(item.createdAt),
                    style: TextStyle(fontSize: 11, color: context.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _delete(item),
                      borderRadius: BorderRadius.circular(8),
                      splashColor: AppColors.error.withOpacity(0.14),
                      highlightColor: AppColors.error.withOpacity(0.07),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                item.originalText,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),

            if (isPlaying && _videoController != null && _videoController!.value.isInitialized)
              SizedBox(
                width: double.infinity,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(color: Colors.black),
                    Center(
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                    Positioned(
                      bottom: 10, right: 14,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () => _disposeVideo(),
                          borderRadius: BorderRadius.circular(20),
                          splashColor: Colors.white24,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: context.dividerColor),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  if (hasVideo) ...[
                    Expanded(
                      child: _ActionButton(
                        icon: isPlaying ? Icons.stop_rounded : Icons.play_circle_outline_rounded,
                        label: isPlaying ? 'Detener' : 'Reproducir',
                        color: AppColors.primary,
                        onTap: () => _togglePlay(item),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share_rounded,
                        label: 'Compartir',
                        color: const Color(0xFF059669),
                        onTap: () => _shareVideo(item),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: context.cardVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off_rounded, size: 14, color: context.textSecondary),
                            const SizedBox(width: 6),
                            Text('Sin video guardado',
                                style: TextStyle(fontSize: 12, color: context.textSecondary)),
                          ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hoy ${_twoDigit(date.hour)}:${_twoDigit(date.minute)}';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${_twoDigit(date.day)}/${_twoDigit(date.month)}/${date.year}';
  }

  String _twoDigit(int n) => n.toString().padLeft(2, '0');
}

// ---------------------------------------------------------------------------
// Widget auxiliar reutilizable
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: color.withOpacity(0.16),
        highlightColor: color.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
