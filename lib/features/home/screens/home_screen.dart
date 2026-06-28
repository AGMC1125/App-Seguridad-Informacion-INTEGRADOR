import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/services/sensitive_data_service.dart';
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

  // ---- Sugerencias de búsqueda semántica ----
  List<SignSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;

  // ---- Avatares disponibles ----
  // IMPORTANTE: los IDs coinciden con los AvatarType del API Spring Boot
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
      _suggestions = [];
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    const SizedBox(height: 20),
                    _buildWelcomeBanner(context, session.userName, session.userEmail),
                    const SizedBox(height: 22),

                    // ---- Paso 1: Avatar ----
                    _buildStepLabel(context, '1', 'Selecciona un avatar'),
                    const SizedBox(height: 4),
                    Text(
                      'El avatar representará las señas en la animación generada',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    _buildAvatarGrid(context),
                    const SizedBox(height: 26),

                    // ---- Paso 2: Texto ----
                    _buildStepLabel(context, '2', 'Escribe el texto'),
                    const SizedBox(height: 4),
                    Text(
                      'El texto será deletreado letra a letra en LSM',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    _buildTextInput(context),
                    const SizedBox(height: 10),
                    _buildSuggestions(context),
                    _buildExampleChips(context),
                    const SizedBox(height: 22),

                    // ---- Error ----
                    if (_errorMessage != null) ...[
                      _buildErrorBanner(_errorMessage!),
                      const SizedBox(height: 16),
                    ],

                    // ---- Botón generar ----
                    _buildGenerateButton(context),

                    // ---- Paso 3: Resultado ----
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
    final userInitial = session.userName.isNotEmpty
        ? session.userName[0].toUpperCase()
        : (session.userEmail.isNotEmpty ? session.userEmail[0].toUpperCase() : 'U');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.4 : 0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo + nombre
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/images/logo-app.png', width: 34, height: 34, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'VirtualSign LSM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Lengua de Señas Mexicana',
                style: TextStyle(fontSize: 9.5, color: context.textSecondary, letterSpacing: 0.2),
              ),
            ],
          ),
          const Spacer(),
          // Avatar de iniciales del usuario
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 4),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                userInitial,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
            onPressed: () => _showSensitiveDataSheet(context, session),
            tooltip: 'Datos sensibles protegidos',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: context.textSecondary, size: 20),
            onPressed: () => _confirmLogout(context, session),
            tooltip: 'Cerrar sesión',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Banner de bienvenida
  // ---------------------------------------------------------------------------

  Widget _buildWelcomeBanner(BuildContext context, String userName, String email) {
    // Prioridad: nombre real del API → parte local del email → fallback
    final displayName = userName.isNotEmpty
        ? userName
        : (email.split('@').first.isNotEmpty
            ? email.split('@').first[0].toUpperCase() + email.split('@').first.substring(1)
            : 'Usuario');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDark
              ? [AppColors.darkPrimaryContainer, AppColors.darkSurfaceVariant]
              : [AppColors.lightPrimaryContainer.withOpacity(0.6), AppColors.lightBackground],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(context.isDark ? 0.25 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '¡Hola, $displayName!',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.waving_hand_rounded, color: AppColors.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Genera señas en LSM letra por letra',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMiniChip(context, Icons.check_circle_rounded, 'LSM', AppColors.accent),
                    const SizedBox(width: 8),
                    _buildMiniChip(context, Icons.smart_display_rounded, '4 Avatares', AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Ícono decorativo
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Etiqueta de paso numerado
  // ---------------------------------------------------------------------------

  Widget _buildStepLabel(BuildContext context, String number, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.30),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Grid de avatares
  // ---------------------------------------------------------------------------

  Widget _buildAvatarGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
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
          color: isSelected
              ? avatar.color.withOpacity(context.isDark ? 0.15 : 0.08)
              : context.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? avatar.color : context.dividerColor,
            width: isSelected ? 2.0 : 1.0,
          ),
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
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: avatar.color.withOpacity(isSelected ? 0.18 : 0.10),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: avatar.color.withOpacity(0.4), width: 2)
                        : null,
                  ),
                  child: Icon(avatar.icon, color: avatar.color, size: 34),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: avatar.color,
                      shape: BoxShape.circle,
                      border: const Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                    child: const Icon(Icons.check, size: 11, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              avatar.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? avatar.color : context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              avatar.description,
              style: TextStyle(fontSize: 10, color: context.textSecondary),
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

  Widget _buildTextInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
          setState(() {
            _result = null;
            _errorMessage = null;
          });
          _fetchSuggestions(value);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Búsqueda semántica — sugerencias del vocabulario de familia
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
            SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text('Buscando señas…',
                style: TextStyle(fontSize: 11, color: context.textSecondary)),
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
                  style: TextStyle(fontSize: 11, color: context.textSecondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _suggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  // Reemplaza la última palabra del texto por la sugerida
                  final parts = _textController.text.trim().split(' ');
                  parts[parts.length - 1] = s.word;
                  _textController.text = '${parts.join(' ')} ';
                  _textController.selection = TextSelection.collapsed(
                      offset: _textController.text.length);
                  setState(() { _suggestions = []; _result = null; _errorMessage = null; });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 8, offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sign_language_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        s.word,
                        style: const TextStyle(
                          fontSize: 12, color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chips de ejemplos rápidos
  // ---------------------------------------------------------------------------

  Widget _buildExampleChips(BuildContext context) {
    final examples = ['Hola', 'Buenos dias', 'Como estas'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ejemplos rápidos:',
          style: TextStyle(fontSize: 11, color: context.textSecondary),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.primaryContainerColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
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
  // Botón generar — gradiente (igual que login)
  // ---------------------------------------------------------------------------

  Widget _buildGenerateButton(BuildContext context) {
    final canGenerate = _selectedAvatarIndex != null &&
        _textController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: canGenerate
              ? const LinearGradient(colors: [AppColors.primary, AppColors.accent])
              : null,
          color: canGenerate ? null : context.dividerColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: canGenerate
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.38),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: ElevatedButton.icon(
          onPressed: canGenerate && !_isGenerating ? _onGenerate : null,
          icon: _isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Icon(Icons.play_circle_filled_rounded, size: 24),
          label: Text(
            _isGenerating ? 'Generando…' : 'Generar en LSM',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: context.textSecondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tarjeta de resultado con reproductor secuencial
  // ---------------------------------------------------------------------------

  Widget _buildResultCard(BuildContext context) {
    final result = _result!;
    final avatar = _avatars[_selectedAvatarIndex!];
    final totalVideos = result.videoUrls.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Reproductor de video ──────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                _buildLetterProgress(context, totalVideos),
                const SizedBox(height: 12),

                // ── Controles prev / next ─────────────────────────────────
                _buildVideoControls(context, totalVideos),
                const SizedBox(height: 14),

                // ── Chips de letras ────────────────────────────────────────
                _buildTokensRow(context, result),

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
                        _suggestions = [];
                      });
                    },
                    icon: Icon(Icons.refresh_rounded, size: 16, color: context.textSecondary),
                    label: Text(
                      'Nueva generación',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
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
        child: Center(
          child: Icon(avatar.icon, color: avatar.color.withOpacity(0.6), size: 72),
        ),
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

  Widget _buildLetterProgress(BuildContext context, int total) {
    final result = _result!;
    final url = result.videoUrls[_currentVideoIndex];
    final letter = url.split('/').last.replaceAll('.mp4', '');

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
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
          style: TextStyle(fontSize: 13, color: context.textSecondary),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                'Listo',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoControls(BuildContext context, int total) {
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
              gradient: !_videoLoading
                  ? const LinearGradient(colors: [AppColors.primary, AppColors.accent])
                  : null,
              color: _videoLoading ? context.dividerColor : null,
              borderRadius: BorderRadius.circular(12),
            ),
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
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: context.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokensRow(BuildContext context, SignResult result) {
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
              gradient: isCurrent
                  ? const LinearGradient(colors: [AppColors.primary, AppColors.accent])
                  : null,
              color: isCurrent ? null : context.cardVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent ? Colors.transparent : context.dividerColor,
              ),
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.white : context.textPrimary,
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
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin seña disponible: ${unsupported.join(', ')}',
              style: TextStyle(fontSize: 11, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hoja de datos sensibles
  // ---------------------------------------------------------------------------

  IconData _sensitiveFieldIcon(String key) {
    if (key.contains('correo')) return Icons.email_outlined;
    if (key.contains('nombre')) return Icons.person_outline_rounded;
    if (key.contains('token') || key.contains('FCM')) return Icons.notifications_outlined;
    if (key.contains('región') || key.contains('region')) return Icons.location_on_outlined;
    return Icons.lock_outline_rounded;
  }

  void _showSensitiveDataSheet(BuildContext context, SessionProvider session) {
    final fields = SensitiveDataService.fieldDescriptions;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datos sensibles protegidos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        'Cifrado AES-256 · Solo en este dispositivo',
                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: context.dividerColor),
            const SizedBox(height: 4),
            ...fields.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(_sensitiveFieldIcon(f.key), color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
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
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'El administrador puede eliminar estos datos remotamente '
                      'enviando una notificación FCM con type: remote_wipe.',
                      style: TextStyle(fontSize: 11, color: AppColors.warning),
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
