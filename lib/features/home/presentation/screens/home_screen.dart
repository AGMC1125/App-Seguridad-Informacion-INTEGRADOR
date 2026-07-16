import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/sensitive_data_service.dart';
import '../../../../features/auth/presentation/providers/session_notifier.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_drawer.dart';
import '../../../generator/presentation/screens/generator_screen.dart';
import '../../../dictionary/presentation/family_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../history/presentation/screens/history_screen.dart';

// ---------------------------------------------------------------------------
// HomeScreen — hub principal de navegación
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionNotifierProvider);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF100510) : Colors.white,
      endDrawer: AppDrawer(
        onShowSensitiveData: () => _showSensitiveDataSheet(context),
        onLogout: () => _confirmLogout(context, ref),
      ),
      drawerScrimColor: Colors.black.withOpacity(0.45),
      body: Stack(
        children: [
          // ── Fondo degradado ──────────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark ? AppGradients.dark : AppGradients.light,
              ),
            ),
          ),
          // ── Blobs decorativos ────────────────────────────────────────────
          Positioned(
            top: -60, right: -40,
            child: AppBlob(size: 210, color: AppColors.primary, opacity: isDark ? 0.09 : 0.07),
          ),
          Positioned(
            bottom: 120, left: -70,
            child: AppBlob(size: 240, color: AppColors.violet, opacity: isDark ? 0.07 : 0.05),
          ),
          Positioned(
            top: 220, right: 20,
            child: AppBlob(size: 100, color: AppColors.accent, opacity: isDark ? 0.05 : 0.04),
          ),
          // ── Contenido principal ──────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Builder(builder: (ctx) => _buildTopBar(ctx, isDark)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 22),
                        _buildWelcomeBanner(context, session.userName, session.userEmail, isDark),
                        const SizedBox(height: 28),
                        _buildSectionLabel(context, '¿QUÉ DESEAS HACER?', isDark),
                        const SizedBox(height: 14),
                        _buildOptionCard(
                          context,
                          isDark: isDark,
                          icon: Icons.keyboard_alt_rounded,
                          title: 'Generador de Señas',
                          subtitle: 'Convierte texto en señas LSM letra por letra usando el abecedario dactilológico',
                          primaryColor: AppColors.primary,
                          gradientEnd: AppColors.primaryDark,
                          badge: 'A – Z',
                          onTap: () => Navigator.push(context, _route(const GeneratorScreen())),
                        ),
                        const SizedBox(height: 12),
                        _buildOptionCard(
                          context,
                          isDark: isDark,
                          icon: Icons.menu_book_rounded,
                          title: 'Diccionario LSM',
                          subtitle: 'Explora el vocabulario por temas: familia, saludos y más',
                          primaryColor: const Color(0xFF059669),
                          gradientEnd: AppColors.accent,
                          badge: '12 señas',
                          onTap: () => Navigator.push(context, _route(const FamilyScreen())),
                        ),
                        const SizedBox(height: 12),
                        _buildOptionCard(
                          context,
                          isDark: isDark,
                          icon: Icons.manage_search_rounded,
                          title: 'Buscador',
                          subtitle: 'Busca palabras con motor semántico BM25 en español',
                          primaryColor: AppColors.violet,
                          gradientEnd: const Color(0xFFA855F7),
                          badge: 'BM25',
                          onTap: () => Navigator.push(context, _route(const SearchScreen())),
                        ),
                        const SizedBox(height: 12),
                        _buildOptionCard(
                          context,
                          isDark: isDark,
                          icon: Icons.history_rounded,
                          title: 'Historial de videos',
                          subtitle: 'Revisa, reproduce y comparte los videos generados anteriormente',
                          primaryColor: const Color(0xFFD97706),
                          gradientEnd: const Color(0xFFF59E0B),
                          badge: 'MP4',
                          onTap: () => Navigator.push(context, _route(const HistoryScreen())),
                        ),
                        const SizedBox(height: 28),
                        _buildStatsRow(context, isDark),
                      ],
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

  // ── Top bar con efecto glass ───────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.22)
                : Colors.white.withOpacity(0.55),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : AppColors.lightDivider.withOpacity(0.6),
              ),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logo-app.png',
                  width: 34, height: 34, fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'VirtualSign LSM',
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: AppColors.primary, letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Lengua de Señas Mexicana',
                    style: TextStyle(
                      fontSize: 9.5, color: context.textSecondary, letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.20)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 10, offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings_rounded, color: AppColors.primary, size: 22),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  tooltip: 'Menú',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────

  Widget _buildSectionLabel(BuildContext context, String text, bool isDark) {
    return Row(
      children: [
        Container(
          width: 18, height: 2,
          decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9,
            color: isDark ? AppColors.primary.withOpacity(0.85) : AppColors.primary,
          ),
        ),
      ],
    );
  }

  // ── Welcome banner con glass ───────────────────────────────────────────────

  Widget _buildWelcomeBanner(
    BuildContext context, String userName, String email, bool isDark,
  ) {
    final displayName = userName.isNotEmpty
        ? userName
        : (email.split('@').first.isNotEmpty
            ? email.split('@').first[0].toUpperCase() +
                email.split('@').first.substring(1)
            : 'Usuario');

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.white.withOpacity(0.85),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.06),
                blurRadius: 24, offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '¡Hola, $displayName!',
                            style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800,
                              color: context.textPrimary, letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis, maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.waving_hand_rounded,
                            color: Color(0xFFF59E0B), size: 18),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Aprende y explora la Lengua de Señas Mexicana',
                      style: TextStyle(
                        fontSize: 12.5, color: context.textSecondary, height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: [
                        _buildTag(context, Icons.check_circle_rounded, 'LSM', AppColors.accent, isDark),
                        _buildTag(context, Icons.smart_display_rounded, '4 avatares', AppColors.primary, isDark),
                        _buildTag(context, Icons.location_on_rounded, 'Chiapas', AppColors.violet, isDark),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 62, height: 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppClay.shadows(AppColors.primary, isDark: isDark),
                ),
                child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(isDark ? 0.25 : 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Option card con clay shadows ───────────────────────────────────────────

  Widget _buildOptionCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required Color gradientEnd,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: primaryColor.withOpacity(0.06),
        highlightColor: primaryColor.withOpacity(0.03),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.70),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.90),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(isDark ? 0.08 : 0.06),
                    blurRadius: 16, offset: const Offset(0, 6),
                  ),
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8, offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [primaryColor, gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppClay.shadows(primaryColor, isDark: isDark),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                  color: context.textPrimary, letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(isDark ? 0.18 : 0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primaryColor.withOpacity(isDark ? 0.30 : 0.25),
                                ),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 9.5, color: primaryColor, fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11.5, color: context.textSecondary, height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: context.textSecondary.withOpacity(0.35),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats strip con glass ──────────────────────────────────────────────────

  Widget _buildStatsRow(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.85),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                _buildStat(context, '27', 'Letras LSM', Icons.abc_rounded, false, isDark),
                _buildStat(context, '12', 'Palabras', Icons.menu_book_rounded, false, isDark),
                _buildStat(context, '4', 'Avatares', Icons.people_rounded, true, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, String value, String label, IconData icon,
    bool isLast, bool isDark,
  ) {
    return Expanded(
      child: Container(
        decoration: isLast
            ? null
            : BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : AppColors.lightDivider,
                  ),
                ),
              ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: AppColors.primary, letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10, color: context.textSecondary, fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Route _route(Widget screen) => MaterialPageRoute(builder: (_) => screen);

  IconData _sensitiveFieldIcon(String key) {
    if (key.contains('correo')) return Icons.email_outlined;
    if (key.contains('nombre')) return Icons.person_outline_rounded;
    if (key.contains('token') || key.contains('FCM')) return Icons.notifications_outlined;
    if (key.contains('región') || key.contains('region')) return Icons.location_on_outlined;
    return Icons.lock_outline_rounded;
  }

  // ── Sensitive data sheet ───────────────────────────────────────────────────

  void _showSensitiveDataSheet(BuildContext context) {
    final fields = SensitiveDataService.fieldDescriptions;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent]),
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
                          fontWeight: FontWeight.bold, fontSize: 15,
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
            ...fields.map((f) => Padding(
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
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14,
                                color: context.textPrimary)),
                        Text(f.classification,
                            style: TextStyle(fontSize: 12, color: context.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.lock, size: 16, color: AppColors.primary),
                ],
              ),
            )),
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
                      'El administrador puede eliminar estos datos desvinculando tu cuenta.',
                      style: TextStyle(fontSize: 12),
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

  // ── Logout dialog ──────────────────────────────────────────────────────────

  void _confirmLogout(BuildContext context, WidgetRef ref) {
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
              ref.read(sessionNotifierProvider.notifier).logout();
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
