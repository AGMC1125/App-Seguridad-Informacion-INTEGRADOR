import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/services/signs_service.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/search_service.dart';
import '../models/sign_result.dart';
import '../../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Modelo de avatar
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
// GeneratorScreen — texto → señas LSM letra por letra
// ---------------------------------------------------------------------------

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  int? _selectedAvatarIndex;
  final _textController = TextEditingController();
  bool _isGenerating = false;
  String? _errorMessage;

  SignResult? _result;

  VideoPlayerController? _videoController;
  int _currentVideoIndex = 0;
  bool _videoLoading = false;

  List<SignSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;

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
    _disposeVideoController();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Video player helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadVideo(int index) async {
    if (_result == null || index >= _result!.videoUrls.length) return;
    setState(() => _videoLoading = true);
    await _disposeVideoController();
    final url = SignsService.buildVideoUrl(_result!.videoUrls[index]);
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      controller.addListener(_onVideoProgress);
      if (!mounted) { controller.dispose(); return; }
      setState(() {
        _videoController = controller;
        _currentVideoIndex = index;
        _videoLoading = false;
      });
      controller.play();
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _videoLoading = false);
      if (index + 1 < (_result?.videoUrls.length ?? 0)) {
        await _loadVideo(index + 1);
      }
    }
  }

  void _onVideoProgress() {
    final controller = _videoController;
    if (controller == null) return;
    final pos = controller.value.position;
    final dur = controller.value.duration;
    if (dur.inMilliseconds > 0 && pos >= dur - const Duration(milliseconds: 200)) {
      final next = _currentVideoIndex + 1;
      if (next < (_result?.videoUrls.length ?? 0)) _loadVideo(next);
    }
  }

  Future<void> _disposeVideoController() async {
    final old = _videoController;
    _videoController = null;
    old?.removeListener(_onVideoProgress);
    await old?.dispose();
  }

  // ---------------------------------------------------------------------------
  // Generar señas
  // ---------------------------------------------------------------------------

  Future<void> _onGenerate() async {
    final avatar = _avatars[_selectedAvatarIndex!];
    final text = _textController.text.trim();
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _result = null;
      _suggestions = [];
    });
    await _disposeVideoController();
    try {
      final result = await SignsService.generate(text: text, avatarCode: avatar.id);
      if (!mounted) return;
      if (result.videoUrls.isEmpty) {
        setState(() { _isGenerating = false; _errorMessage = 'No se encontraron señas para el texto ingresado.'; });
        return;
      }
      setState(() { _result = result; _isGenerating = false; });
      await _loadVideo(0);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _isGenerating = false; _errorMessage = e.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _isGenerating = false; _errorMessage = 'No se pudo conectar con el servidor.'; });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Generador de Señas',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
        backgroundColor: context.cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.dividerColor),
        ),
      ),
      body: SingleChildScrollView(
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
            _buildAvatarGrid(context),
            const SizedBox(height: 26),

            // Paso 2: Texto
            _buildStepLabel(context, '2', 'Escribe el texto'),
            const SizedBox(height: 4),
            Text('El texto será deletreado letra a letra en LSM',
                style: TextStyle(fontSize: 12, color: context.textSecondary)),
            const SizedBox(height: 14),
            _buildTextInput(context),
            const SizedBox(height: 10),
            _buildSuggestions(context),
            _buildExampleChips(context),
            const SizedBox(height: 22),

            if (_errorMessage != null) ...[
              _buildErrorBanner(_errorMessage!),
              const SizedBox(height: 16),
            ],

            _buildGenerateButton(context),

            if (_result != null) ...[
              const SizedBox(height: 32),
              _buildStepLabel(context, '3', 'Reproducción de señas'),
              const SizedBox(height: 14),
              _buildResultCard(context),
            ],

            const SizedBox(height: 36),
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

  Widget _buildAvatarGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15,
      ),
      itemCount: _avatars.length,
      itemBuilder: (_, index) => _buildAvatarCard(context, index),
    );
  }

  Widget _buildAvatarCard(BuildContext context, int index) {
    final avatar = _avatars[index];
    final isSelected = _selectedAvatarIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedAvatarIndex = index;
        _result = null;
        _errorMessage = null;
        _disposeVideoController();
      }),
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

  Widget _buildTextInput(BuildContext context) {
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
          setState(() { _result = null; _errorMessage = null; });
          _fetchSuggestions(value);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sugerencias semánticas
  // ---------------------------------------------------------------------------

  Future<void> _fetchSuggestions(String text) async {
    final lastWord = text.trim().split(' ').last;
    if (lastWord.length < 2) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    setState(() => _loadingSuggestions = true);
    final results = await SearchService.search(lastWord);
    if (mounted) setState(() { _suggestions = results; _loadingSuggestions = false; });
  }

  Widget _buildSuggestions(BuildContext context) {
    if (_loadingSuggestions) {
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
    if (_suggestions.isEmpty) return const SizedBox.shrink();
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
            children: _suggestions.map((s) => GestureDetector(
              onTap: () {
                final parts = _textController.text.trim().split(' ');
                parts[parts.length - 1] = s.word;
                _textController.text = '${parts.join(' ')} ';
                _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
                setState(() { _suggestions = []; _result = null; _errorMessage = null; });
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
            onTap: () => setState(() { _textController.text = e; _result = null; _errorMessage = null; }),
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

  Widget _buildGenerateButton(BuildContext context) {
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
          onPressed: canGenerate && !_isGenerating ? _onGenerate : null,
          icon: _isGenerating
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Icon(Icons.play_circle_filled_rounded, size: 24),
          label: Text(_isGenerating ? 'Generando…' : 'Generar en LSM',
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

  Widget _buildResultCard(BuildContext context) {
    final result = _result!;
    final avatar = _avatars[_selectedAvatarIndex!];
    final totalVideos = result.videoUrls.length;
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
                _buildLetterProgress(context, totalVideos),
                const SizedBox(height: 12),
                _buildVideoControls(context, totalVideos),
                const SizedBox(height: 14),
                _buildTokensRow(context, result),
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
                      setState(() {
                        _result = null; _errorMessage = null;
                        _textController.clear(); _selectedAvatarIndex = null;
                        _currentVideoIndex = 0; _suggestions = [];
                      });
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
        Positioned(top: 10, left: 14, child: _buildLetterBadge(avatar.color)),
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

  Widget _buildLetterBadge(Color color) {
    final result = _result;
    if (result == null) return const SizedBox.shrink();
    final letter = result.videoUrls[_currentVideoIndex].split('/').last.replaceAll('.mp4', '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
      child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLetterProgress(BuildContext context, int total) {
    final letter = _result!.videoUrls[_currentVideoIndex].split('/').last.replaceAll('.mp4', '');
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        const SizedBox(width: 10),
        Text('Seña ${_currentVideoIndex + 1} de $total', style: TextStyle(fontSize: 13, color: context.textSecondary)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
            const SizedBox(width: 4),
            Text('Listo', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
          ]),
        ),
      ],
    );
  }

  Widget _buildVideoControls(BuildContext context, int total) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _currentVideoIndex > 0 && !_videoLoading ? () => _loadVideo(_currentVideoIndex - 1) : null,
            icon: const Icon(Icons.skip_previous_rounded, size: 18),
            label: const Text('Anterior', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: !_videoLoading ? const LinearGradient(colors: [AppColors.primary, AppColors.accent]) : null,
              color: _videoLoading ? context.dividerColor : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: !_videoLoading
                  ? () => _loadVideo(_currentVideoIndex < total - 1 ? _currentVideoIndex + 1 : 0)
                  : null,
              icon: Icon(_currentVideoIndex < total - 1 ? Icons.skip_next_rounded : Icons.replay_rounded, size: 18),
              label: Text(_currentVideoIndex < total - 1 ? 'Siguiente' : 'Repetir',
                  style: const TextStyle(fontSize: 12)),
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

  Widget _buildTokensRow(BuildContext context, SignResult result) {
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: List.generate(result.videoUrls.length, (i) {
        final letter = result.videoUrls[i].split('/').last.replaceAll('.mp4', '');
        final isCurrent = i == _currentVideoIndex;
        return GestureDetector(
          onTap: () => _loadVideo(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: isCurrent ? const LinearGradient(colors: [AppColors.primary, AppColors.accent]) : null,
              color: isCurrent ? null : context.cardVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isCurrent ? Colors.transparent : context.dividerColor),
            ),
            child: Text(letter,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                    color: isCurrent ? Colors.white : context.textPrimary)),
          ),
        );
      }),
    );
  }

  Widget _buildUnsupportedChips(List<String> unsupported) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text('Sin seña disponible: ${unsupported.join(', ')}',
              style: TextStyle(fontSize: 11, color: AppColors.warning))),
        ],
      ),
    );
  }
}
