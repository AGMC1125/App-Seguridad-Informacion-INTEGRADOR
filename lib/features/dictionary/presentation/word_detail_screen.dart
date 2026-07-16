import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_constants.dart';
import '../../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// WordDetailScreen — reproduce el video de una palabra del diccionario
// ---------------------------------------------------------------------------

class WordDetailScreen extends StatefulWidget {
  final String word;
  final String initialAvatarCode;

  const WordDetailScreen({
    super.key,
    required this.word,
    this.initialAvatarCode = 'nino',
  });

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  late String _selectedAvatarCode;
  VideoPlayerController? _videoController;
  bool _videoLoading = true;
  bool _videoError = false;
  String _debugError = '';

  static const _avatars = [
    (id: 'nino',         icon: Icons.boy_rounded,    label: 'Niño',   color: Color(0xFF2563EB)),
    (id: 'nina',         icon: Icons.girl_rounded,   label: 'Niña',   color: Color(0xFFDB2777)),
    (id: 'hombre_adulto',icon: Icons.man_rounded,    label: 'Hombre', color: Color(0xFF059669)),
    (id: 'mujer_adulta', icon: Icons.woman_rounded,  label: 'Mujer',  color: Color(0xFF7C3AED)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedAvatarCode = widget.initialAvatarCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadVideo();
    });
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _disposeController() async {
    final old = _videoController;
    _videoController = null;
    await old?.dispose();
  }

  /// URL construida directamente — sin dependencias de SignsService.
  String _buildVideoUrl() =>
      '${AppConstants.apiBaseUrl}/signs/$_selectedAvatarCode/${widget.word}.mp4';

  Future<void> _loadVideo() async {
    if (!mounted) return;
    setState(() { _videoLoading = true; _videoError = false; });
    await _disposeController();

    final url = _buildVideoUrl();

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (!mounted) { controller.dispose(); return; }

      setState(() { _videoController = controller; _videoLoading = false; _debugError = ''; });
      controller.setLooping(true);
      controller.play();
    } catch (e) {
      if (mounted) setState(() { _videoLoading = false; _videoError = true; _debugError = e.toString(); });
    }
  }

  void _selectAvatar(String avatarCode) {
    if (_selectedAvatarCode == avatarCode) return;
    setState(() => _selectedAvatarCode = avatarCode);
    _loadVideo();
  }

  @override
  Widget build(BuildContext context) {
    final avatarInfo = _avatars.firstWhere((a) => a.id == _selectedAvatarCode, orElse: () => _avatars.first);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _capitalize(widget.word),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
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
            // ── Video player ───────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                height: 280,
                color: const Color(0xFF0F172A),
                child: _buildVideoArea(avatarInfo),
              ),
            ),
            const SizedBox(height: 20),

            // ── Word + sign icon ───────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalize(widget.word),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    Text('Vocabulario de familia · LSM',
                        style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Selector de avatar ─────────────────────────────────────────
            Text('Selecciona el avatar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: _avatars.map((a) {
                final isSelected = _selectedAvatarCode == a.id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _selectAvatar(a.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? a.color.withOpacity(context.isDark ? 0.2 : 0.1) : context.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? a.color : context.dividerColor, width: isSelected ? 2 : 1),
                        boxShadow: isSelected
                            ? [BoxShadow(color: a.color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3))]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Icon(a.icon, color: a.color, size: 28),
                          const SizedBox(height: 4),
                          Text(a.label,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                  color: isSelected ? a.color : context.textSecondary),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Replay button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: ElevatedButton.icon(
                  onPressed: _videoLoading ? null : _loadVideo,
                  icon: _videoLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.replay_rounded, size: 20),
                  label: Text(_videoLoading ? 'Cargando…' : 'Repetir seña',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea(({String id, IconData icon, String label, Color color}) avatarInfo) {
    if (_videoLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white54),
            if (_debugError.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_debugError,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                    textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      );
    }
    if (_videoError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              const Text('No se pudo cargar el video', style: TextStyle(color: Colors.white54, fontSize: 13)),
              if (_debugError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _debugError,
                  style: const TextStyle(color: Colors.orange, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return Center(child: Icon(avatarInfo.icon, color: avatarInfo.color.withOpacity(0.5), size: 80));
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(color: Colors.black),
        ClipRect(
          child: Transform.scale(
            scale: 2.2,
            alignment: const Alignment(0, -0.4),
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12, right: 14,
          child: ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, value, __) {
              return GestureDetector(
                onTap: () => value.isPlaying ? controller.pause() : controller.play(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Icon(value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 22),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 10, left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: avatarInfo.color.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_capitalize(widget.word),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
