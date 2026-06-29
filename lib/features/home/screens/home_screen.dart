import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/services/sensitive_data_service.dart';
import '../../../theme/app_theme.dart';
import 'generator_screen.dart';
import '../../dictionary/screens/family_screen.dart';
import '../../search/screens/search_screen.dart';

// ---------------------------------------------------------------------------
// HomeScreen — hub principal de navegación
// ---------------------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                    const SizedBox(height: 28),

                    Text(
                      '¿Qué deseas hacer?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Selecciona una opción para comenzar',
                      style: TextStyle(fontSize: 13, color: context.textSecondary),
                    ),
                    const SizedBox(height: 18),

                    // ── Opción 1: Generador ────────────────────────────────
                    _buildOptionCard(
                      context,
                      icon: Icons.keyboard_alt_rounded,
                      title: 'Generador de Señas',
                      subtitle: 'Convierte texto en señas LSM letra por letra usando el abecedario dactilológico',
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      badge: 'A-Z',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GeneratorScreen())),
                    ),
                    const SizedBox(height: 14),

                    // ── Opción 2: Diccionario ──────────────────────────────
                    _buildOptionCard(
                      context,
                      icon: Icons.menu_book_rounded,
                      title: 'Diccionario LSM',
                      subtitle: 'Explora el vocabulario disponible por temas: familia, saludos y más',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      badge: '12 señas',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyScreen())),
                    ),
                    const SizedBox(height: 14),

                    // ── Opción 3: Buscador ─────────────────────────────────
                    _buildOptionCard(
                      context,
                      icon: Icons.manage_search_rounded,
                      title: 'Buscador',
                      subtitle: 'Busca palabras del diccionario con motor semántico BM25 en español',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      badge: 'BM25',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                    ),

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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              Text(
                'Lengua de Señas Mexicana',
                style: TextStyle(fontSize: 9.5, color: context.textSecondary, letterSpacing: 0.2),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 32, height: 32,
            margin: const EdgeInsets.only(right: 4),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(userInitial,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
  // Welcome banner
  // ---------------------------------------------------------------------------

  Widget _buildWelcomeBanner(BuildContext context, String userName, String email) {
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
        border: Border.all(color: AppColors.primary.withOpacity(context.isDark ? 0.25 : 0.15)),
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
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.waving_hand_rounded, color: AppColors.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Aprende y explora la Lengua de Señas Mexicana',
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
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
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
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Option card
  // ---------------------------------------------------------------------------

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required String badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDark ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gradient icon box
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: gradient.colors.first.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: gradient.colors.first.withOpacity(0.3)),
                        ),
                        child: Text(badge,
                            style: TextStyle(fontSize: 10, color: gradient.colors.first, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: context.textSecondary.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sensitive data sheet
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                      Text('Datos sensibles protegidos',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.cardColor == Theme.of(sheetCtx).cardColor ? null : null)),
                      Text('Cifrado AES-256 · Solo en este dispositivo',
                          style: TextStyle(fontSize: 12, color: context.textSecondary)),
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
                          Text(f.key,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
                          Text(f.classification,
                              style: TextStyle(
                                fontSize: 11,
                                color: f.classification.contains('Ultra') ? AppColors.error : AppColors.primary,
                                fontWeight: FontWeight.w500,
                              )),
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
  // Logout
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
            onPressed: () { Navigator.pop(context); session.logout(); },
            child: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
