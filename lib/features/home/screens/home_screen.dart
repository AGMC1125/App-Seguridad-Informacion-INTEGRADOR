import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/services/sensitive_data_service.dart';
import '../../../theme/app_theme.dart';
import '../widgets/lesson_card.dart';
import '../widgets/progress_section.dart';
import '../widgets/quick_practice_section.dart';

/// Pantalla principal de AprendIA.
///
/// Muestra el dashboard del usuario con:
/// - Saludo personalizado y racha de días
/// - Progreso general del curso
/// - Lecciones disponibles (mock data)
/// - Práctica rápida
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                    _buildGreeting(session.userEmail),
                    const SizedBox(height: 24),
                    const ProgressSection(),
                    const SizedBox(height: 28),
                    _buildSectionTitle(context, 'Continúa aprendiendo'),
                    const SizedBox(height: 14),
                    _buildLessonList(),
                    const SizedBox(height: 28),
                    _buildSectionTitle(context, 'Práctica rápida'),
                    const SizedBox(height: 14),
                    const QuickPracticeSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widgets internos
  Widget _buildTopBar(BuildContext context, SessionProvider session) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
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
            child: const Icon(
              Icons.sign_language,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'AprendIA',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Racha de días
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Text('🔥', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text(
                  '7 días',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Botón datos sensibles
          IconButton(
            icon: const Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 22,
            ),
            onPressed: () => _showSensitiveDataSheet(context, session),
            tooltip: 'Datos sensibles protegidos',
          ),
          // Botón logout
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: () => _confirmLogout(context, session),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(String email) {
    // Extraer nombre del email para el saludo
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
          'Sigue practicando tu LSM de hoy',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildLessonList() {
    return Column(
      children: [
        LessonCard(
          icon: '🤟',
          title: 'Alfabeto en LSM',
          subtitle: 'Aprende las 27 letras del abecedario',
          progress: 0.65,
          isLocked: false,
          lessonNumber: 1,
        ),
        const SizedBox(height: 12),
        LessonCard(
          icon: '👋',
          title: 'Saludos básicos',
          subtitle: 'Hola, adiós, gracias y más',
          progress: 0.30,
          isLocked: false,
          lessonNumber: 2,
        ),
        const SizedBox(height: 12),
        LessonCard(
          icon: '🔢',
          title: 'Números del 1 al 20',
          subtitle: 'Cuenta y comunica cantidades',
          progress: 0.0,
          isLocked: true,
          lessonNumber: 3,
        ),
        const SizedBox(height: 12),
        LessonCard(
          icon: '👨‍👩‍👧',
          title: 'Familia y personas',
          subtitle: 'Vocabulario de relaciones personales',
          progress: 0.0,
          isLocked: true,
          lessonNumber: 4,
        ),
      ],
    );
  }

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
                    color: AppColors.primary.withAlpha(25),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
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
            ...fields.map((f) => Padding(
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
                      const Icon(Icons.lock, size: 16, color: AppColors.primary),
                    ],
                  ),
                )),
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
                      'El administrador puede eliminar estos datos remotamente enviando una notificación FCM con type: remote_wipe.',
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
