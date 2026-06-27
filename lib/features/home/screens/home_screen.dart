import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/services/sensitive_data_service.dart';
import '../../../core/services/signs_service.dart';
import '../../../core/services/api_client.dart';
import '../models/sign_result.dart';
import '../../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Modelo de avatar
// ---------------------------------------------------------------------------

class _AvatarOption {
  final String id;
  final String emoji;
  final String label;
  final String description;
  final Color color;

  const _AvatarOption({
    required this.id,
    required this.emoji,
    required this.label,
    required this.description,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

/// Pantalla principal de AprendIA.
///
/// Flujo principal:
///   1. El usuario selecciona uno de los 4 avatares disponibles.
///   2. Ingresa texto en español.
///   3. Presiona "Generar" → la API devuelve videos LSM por cada letra/token.
///   4. Se reproducen secuencialmente en el reproductor integrado.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---- Estado del flujo ----
  int? _selectedAvatarIndex;
  final _textController = TextEditingController();
  bool _isGenerating = false;
  String? _errorMessage;

  // ---- Resultado de la API ----
  SignResult? _result;

  // ---- Reproductor de video ----
  VideoPlayerController? _videoController;
  int _currentVideoIndex = 0;
  bool _videoLoading = false;

  // ---- Avatares disponibles ----
  // IMPORTANTE: los IDs coinciden con los AvatarType del API Spring Boot
  static const List<_AvatarOption> _avatars = [
    _AvatarOption(
      id: 'nino',
      emoji: '👦',
      label: 'Niño',
      description: 'Avatar infantil masculino',
      color: Color(0xFF2563EB),
    ),
    _AvatarOption(
      id: 'nina',
      emoji: '👧',
      label: 'Niña',
      description: 'Avatar infantil femenino',
      color: Color(0xFFDB2777),
    ),
    _AvatarOption(
      id: 'hombre_adulto',
      emoji: '👨',
      label: 'Hombre adulto',
      description: 'Avatar adulto masculino',
      color: Color(0xFF059669),
    ),
    _AvatarOption(
      id: 'mujer_adulta',
      emoji: '👩',
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
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _currentVideoIndex = index;
        _videoLoading = false;
      });
      controller.play();
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _videoLoading = false);
      // Si falla un video, avanzar al siguiente automáticamente
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
    // Avanzar al siguiente video cuando termina el actual
    if (dur.inMilliseconds > 0 && pos >= dur - const Duration(milliseconds: 200)) {
      final next = _currentVideoIndex + 1;
      if (next < (_result?.videoUrls.length ?? 0)) {
        _loadVideo(next);
      }
    }
  }

  Future<void> _disposeVideoController() async {
    final old = _videoController;
    _videoController = null;
    old?.removeListener(_onVideoProgress);
    await old?.dispose();
  }

  // ---------------------------------------------------------------------------
  // Generar señas (llamada real a la API)
  // ---------------------------------------------------------------------------

  Future<void> _onGenerate() async {
    final avatar = _avatars[_selectedAvatarIndex!];
    final text = _textController.text.trim();

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _result = null;
    });

    await _disposeVideoController();

    try {
      final result = await SignsService.generate(
        text: text,
        avatarCode: avatar.id,
      );

      if (!mounted) return;

      if (result.videoUrls.isEmpty) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'No se encontraron señas para el texto ingresado.';
        });
        return;
      }

      setState(() {
        _result = result;
        _isGenerating = false;
      });

      // Cargar y reproducir el primer video
      await _loadVideo(0);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = 'No se pudo conectar con el servidor.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build principal
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, session),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildWelcomeHeader(session.userEmail),
                    const SizedBox(height: 20),
                    _buildInfoBanner(),
                    const SizedBox(height: 28),

                    // ---- Paso 1: Avatar ----
                    _buildStepLabel('1', 'Selecciona un avatar'),
                    const SizedBox(height: 4),
                    const Text(
                      'El avatar representará las señas en la animación generada',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    _buildAvatarGrid(),
                    const SizedBox(height: 28),

                    // ---- Paso 2: Texto ----
                    _buildStepLabel('2', 'Escribe el texto'),
                    const SizedBox(height: 4),
                    const Text(
                      'El texto será deletreado letra a letra en Lengua de Señas Mexicana (LSM)',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    _buildTextInput(),
                    const SizedBox(height: 8),
                    _buildExampleChips(),
                    const SizedBox(height: 24),

                    // ---- Error ----
                    if (_errorMessage != null) ...[
                      _buildErrorBanner(_errorMessage!),
                      const SizedBox(height: 16),
                    ],

                    // ---- Botón generar ----
                    _buildGenerateButton(),

                    // ---- Paso 3: Resultado ----
                    if (_result != null) ...[
                      const SizedBox(height: 32),
                      _buildStepLabel('3', 'Reproducción de señas'),
                      const SizedBox(height: 14),
                      _buildResultCard(),
                    ],

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(BuildContext context, SessionProvider session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/images/logo-app.png', width: 36, height: 36, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          const Text(
            'AprendIA',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
            onPressed: () => _showSensitiveDataSheet(context, session),
            tooltip: 'Datos sensibles protegidos',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 22),
            onPressed: () => _confirmLogout(context, session),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Encabezado de bienvenida
  // ---------------------------------------------------------------------------

  Widget _buildWelcomeHeader(String email) {
    final name = email.split('@').first;
    final displayName = name[0].toUpperCase() + name.substring(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Hola, $displayName! 👋',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Genera instrucciones en Lengua de Señas Mexicana',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Banner informativo
  // ---------------------------------------------------------------------------

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Selecciona un avatar, escribe el texto y obtén los videos LSM letra por letra.',
              style: TextStyle(fontSize: 12, color: AppColors.primary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Etiqueta de paso numerado
  // ---------------------------------------------------------------------------

  Widget _buildStepLabel(String number, String title) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Grid de avatares
  // ---------------------------------------------------------------------------

  Widget _buildAvatarGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: _avatars.length,
      itemBuilder: (_, index) => _buildAvatarCard(index),
    );
  }

  Widget _buildAvatarCard(int index) {
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
          color: isSelected ? avatar.color.withOpacity(0.10) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? avatar.color : AppColors.divider,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: avatar.color.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 3))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Text(avatar.emoji, style: const TextStyle(fontSize: 38)),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: avatar.color, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              avatar.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? avatar.color : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              avatar.description,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Campo de texto
  // ---------------------------------------------------------------------------

  Widget _buildTextInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: _textController,
        maxLines: 3,
        maxLength: 200,
        decoration: InputDecoration(
          hintText: 'Ej: Hola, que tal?',
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          counterStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10, top: 14),
            child: Icon(Icons.text_fields_rounded, color: AppColors.primary, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
        ),
        onChanged: (_) => setState(() {
          _result = null;
          _errorMessage = null;
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chips de ejemplos rápidos
  // ---------------------------------------------------------------------------

  Widget _buildExampleChips() {
    final examples = ['Hola', 'Buenos dias', 'Como estas'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ejemplos rápidos:',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: examples
              .map(
                (e) => GestureDetector(
                  onTap: () => setState(() {
                    _textController.text = e;
                    _result = null;
                    _errorMessage = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Banner de error
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
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.error, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Botón generar
  // ---------------------------------------------------------------------------

  Widget _buildGenerateButton() {
    final canGenerate = _selectedAvatarIndex != null &&
        _textController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canGenerate && !_isGenerating ? _onGenerate : null,
        icon: _isGenerating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Icon(Icons.play_circle_filled_rounded, size: 22),
        label: Text(
          _isGenerating ? 'Generando…' : 'Generar en LSM',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canGenerate ? AppColors.primary : AppColors.divider,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: canGenerate ? 2 : 0,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tarjeta de resultado con reproductor secuencial
  // ---------------------------------------------------------------------------

  Widget _buildResultCard() {
    final result = _result!;
    final avatar = _avatars[_selectedAvatarIndex!];
    final totalVideos = result.videoUrls.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Reproductor de video ──────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              width: double.infinity,
              height: 240,
              child: _buildVideoPlayer(avatar),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Letra actual + progreso ───────────────────────────────
                _buildLetterProgress(totalVideos),
                const SizedBox(height: 12),

                // ── Controles prev / next ─────────────────────────────────
                _buildVideoControls(totalVideos),
                const SizedBox(height: 14),

                // ── Chips de letras ────────────────────────────────────────
                _buildTokensRow(result),

                // ── Caracteres no soportados ──────────────────────────────
                if (result.unsupportedCharacters.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildUnsupportedChips(result.unsupportedCharacters),
                ],

                const SizedBox(height: 14),

                // ── Botón nueva generación ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      _disposeVideoController();
                      setState(() {
                        _result = null;
                        _errorMessage = null;
                        _textController.clear();
                        _selectedAvatarIndex = null;
                        _currentVideoIndex = 0;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Nueva generación', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
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
      return Container(
        color: const Color(0xFF0F172A),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      );
    }

    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: const Color(0xFF0F172A),
        child: Center(child: Text(avatar.emoji, style: const TextStyle(fontSize: 64))),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(color: Colors.black),
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        // Badge: letra actual
        Positioned(
          top: 10,
          left: 14,
          child: _buildLetterBadge(avatar.color),
        ),
        // Botón pausa/play
        Positioned(
          bottom: 10,
          right: 14,
          child: ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, value, __) {
              final isPlaying = value.isPlaying;
              return GestureDetector(
                onTap: () => isPlaying ? controller.pause() : controller.play(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
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
    final url = result.videoUrls[_currentVideoIndex];
    final letter = url.split('/').last.replaceAll('.mp4', '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        letter,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLetterProgress(int total) {
    final result = _result!;
    final url = result.videoUrls[_currentVideoIndex];
    final letter = url.split('/').last.replaceAll('.mp4', '');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            letter,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Seña ${_currentVideoIndex + 1} de $total',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
              SizedBox(width: 4),
              Text('Listo', style: TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoControls(int total) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _currentVideoIndex > 0 && !_videoLoading
                ? () => _loadVideo(_currentVideoIndex - 1)
                : null,
            icon: const Icon(Icons.skip_previous_rounded, size: 18),
            label: const Text('Anterior', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: !_videoLoading
                ? () => _loadVideo(_currentVideoIndex < total - 1 ? _currentVideoIndex + 1 : 0)
                : null,
            icon: Icon(
              _currentVideoIndex < total - 1 ? Icons.skip_next_rounded : Icons.replay_rounded,
              size: 18,
            ),
            label: Text(
              _currentVideoIndex < total - 1 ? 'Siguiente' : 'Repetir',
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokensRow(SignResult result) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(result.videoUrls.length, (i) {
        final url = result.videoUrls[i];
        final letter = url.split('/').last.replaceAll('.mp4', '');
        final isCurrent = i == _currentVideoIndex;

        return GestureDetector(
          onTap: () => _loadVideo(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.primary : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildUnsupportedChips(List<String> unsupported) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin seña disponible: ${unsupported.join(', ')}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9A3412)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hoja de datos sensibles
  // ---------------------------------------------------------------------------

  void _showSensitiveDataSheet(BuildContext context, SessionProvider session) {
    final fields = SensitiveDataService.fieldDescriptions;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datos sensibles protegidos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Cifrado AES-256 · Solo en este dispositivo',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 4),
            ...fields.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(f.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.key,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          Text(
                            f.classification,
                            style: TextStyle(
                              fontSize: 11,
                              color: f.classification.contains('Ultra') ? AppColors.error : AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFE65100)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El administrador puede eliminar estos datos remotamente '
                      'enviando una notificación FCM con type: remote_wipe.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFE65100)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Diálogo de logout
  // ---------------------------------------------------------------------------

  void _confirmLogout(BuildContext context, SessionProvider session) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              session.logout();
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
