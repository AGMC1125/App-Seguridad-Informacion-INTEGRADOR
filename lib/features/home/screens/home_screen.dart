import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/services/sensitive_data_service.dart';
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
///   2. Ingresa una instrucción en texto español.
///   3. Presiona "Generar" → el sistema produce una animación LSM con el avatar.
///   4. Puede previsualizar y descargar el resultado (GIF / MP4).
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
  bool _hasResult = false;

  // ---- Avatares disponibles ----
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
      id: 'hombre',
      emoji: '👨',
      label: 'Hombre adulto',
      description: 'Avatar adulto masculino',
      color: Color(0xFF059669),
    ),
    _AvatarOption(
      id: 'mujer',
      emoji: '👩',
      label: 'Mujer adulta',
      description: 'Avatar adulto femenino',
      color: Color(0xFF7C3AED),
    ),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // ---- Build principal ----

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
                    _buildStepLabel('2', 'Escribe la instrucción'),
                    const SizedBox(height: 4),
                    const Text(
                      'La instrucción será traducida a Lengua de Señas Mexicana (LSM)',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    _buildTextInput(),
                    const SizedBox(height: 8),
                    _buildExampleChips(),
                    const SizedBox(height: 24),

                    // ---- Botón generar ----
                    _buildGenerateButton(),

                    // ---- Paso 3: Resultado ----
                    if (_hasResult) ...[
                      const SizedBox(height: 32),
                      _buildStepLabel('3', 'Resultado generado'),
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
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.sign_language, color: Colors.white, size: 20),
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
          // Botón seguridad
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
            onPressed: () => _showSensitiveDataSheet(context, session),
            tooltip: 'Datos sensibles protegidos',
          ),
          // Botón logout
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
              'Selecciona un avatar, escribe la instrucción y obtén una animación LSM lista para usar en AprendIA.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                height: 1.4,
              ),
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
        _hasResult = false;
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
              ? [
                  BoxShadow(
                    color: avatar.color.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
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
                    decoration: BoxDecoration(
                      color: avatar.color,
                      shape: BoxShape.circle,
                    ),
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
          hintText:
              'Ej: Relaciona las palabras con la seña que le corresponde',
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          counterStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10, top: 14),
            child: Icon(Icons.text_fields_rounded,
                color: AppColors.primary, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
        ),
        onChanged: (_) => setState(() {
          _hasResult = false;
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chips de ejemplos rápidos
  // ---------------------------------------------------------------------------

  Widget _buildExampleChips() {
    final examples = [
      'Relaciona las palabras con su seña',
      'Elige el mes correcto',
      'Selecciona el número que ves',
    ];

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
                    _hasResult = false;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      e,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
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
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Icon(Icons.play_circle_filled_rounded, size: 22),
        label: Text(
          _isGenerating ? 'Generando animación…' : 'Generar animación en LSM',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canGenerate ? AppColors.primary : AppColors.divider,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: canGenerate ? 2 : 0,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tarjeta de resultado
  // ---------------------------------------------------------------------------

  Widget _buildResultCard() {
    final avatar = _avatars[_selectedAvatarIndex!];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Preview simulado ----
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fondo decorativo
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    child: CustomPaint(
                      painter: _GridPainter(),
                    ),
                  ),
                ),
                // Avatar y label
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(avatar.emoji,
                        style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_outline,
                              color: Colors.white70, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Animación LSM generada',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Duración simulada
                Positioned(
                  bottom: 12,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '0:08',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Badge de formato
                Positioned(
                  bottom: 12,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: avatar.color.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'GIF · MP4',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---- Info del resultado ----
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: avatar.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(avatar.emoji,
                          style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Avatar: ${avatar.label}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Generado correctamente',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 12, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text(
                            'Listo',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF065F46),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Texto ingresado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"${_textController.text.trim()}"',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDownloadDialog('GIF'),
                        icon: const Icon(Icons.gif_box_outlined, size: 18),
                        label: const Text('Descargar GIF',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding:
                              const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showDownloadDialog('MP4'),
                        icon: const Icon(Icons.video_file_outlined, size: 18),
                        label: const Text('Descargar MP4',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Botón nueva generación
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _hasResult = false;
                      _textController.clear();
                      _selectedAvatarIndex = null;
                    }),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Generar otra instrucción',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
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
  // Acciones simuladas
  // ---------------------------------------------------------------------------

  Future<void> _onGenerate() async {
    setState(() {
      _isGenerating = true;
      _hasResult = false;
    });
    // Simulación de llamada a la API (2 segundos)
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _hasResult = true;
    });
  }

  void _showDownloadDialog(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Descarga de $format iniciada (simulada)',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hoja de datos sensibles (igual que antes)
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
                  child: const Icon(Icons.shield,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Datos sensibles protegidos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Cifrado AES-256 · Solo en este dispositivo',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            f.classification,
                            style: TextStyle(
                              fontSize: 11,
                              color: f.classification.contains('Ultra')
                                  ? AppColors.error
                                  : AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock,
                        size: 16, color: AppColors.primary),
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
                  Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFE65100)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El administrador puede eliminar estos datos remotamente '
                      'enviando una notificación FCM con type: remote_wipe.',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFFE65100)),
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
        content:
            const Text('¿Estás seguro que deseas cerrar tu sesión?'),
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
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pintor de fondo de cuadrícula (decorativo para el preview del video)
// ---------------------------------------------------------------------------

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
