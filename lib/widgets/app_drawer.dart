import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/providers/session_notifier.dart';
import '../theme/app_theme.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/auth/presentation/screens/terms_and_conditions_screen.dart';
import '../features/auth/presentation/screens/privacy_policy_screen.dart';

/// Sidebar deslizante con efecto glassmorphism.
/// Contiene: info del usuario, perfil, datos de seguridad, cerrar sesión.
class AppDrawer extends ConsumerWidget {
  final VoidCallback onShowSensitiveData;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.onShowSensitiveData,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionNotifierProvider);
    final isDark = context.isDark;
    final screenW = MediaQuery.of(context).size.width;
    final drawerWidth = (screenW > 420 ? 300.0 : screenW * 0.82).clamp(260.0, 340.0);

    final userInitial = session.userName.isNotEmpty
        ? session.userName[0].toUpperCase()
        : (session.userEmail.isNotEmpty ? session.userEmail[0].toUpperCase() : 'U');

    final displayName = session.userName.isNotEmpty
        ? session.userName
        : (session.userEmail.contains('@')
            ? session.userEmail.split('@').first
            : session.userEmail);

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            width: drawerWidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF060C1E).withOpacity(0.94),
                        const Color(0xFF090614).withOpacity(0.94),
                      ]
                    : [
                        Colors.white.withOpacity(0.90),
                        const Color(0xFFF4F0FF).withOpacity(0.90),
                      ],
              ),
              border: Border(
                left: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : AppColors.lightDivider.withOpacity(0.8),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header con info del usuario ──────────────────────────
                  _DrawerHeader(
                    isDark: isDark,
                    userInitial: userInitial,
                    displayName: displayName,
                    email: session.userEmail,
                  ),
                  Divider(
                    color: isDark
                        ? Colors.white.withOpacity(0.07)
                        : AppColors.lightDivider,
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  const SizedBox(height: 16),
                  // ── Sección: Navegación ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'CUENTA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _DrawerNavItem(
                          isDark: isDark,
                          icon: Icons.manage_accounts_rounded,
                          label: 'Mi perfil',
                          subtitle: 'Editar nombre y contraseña',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        _DrawerNavItem(
                          isDark: isDark,
                          icon: Icons.shield_rounded,
                          label: 'Datos sensibles',
                          subtitle: 'Cifrado AES-256 · Este dispositivo',
                          color: AppColors.violet,
                          onTap: () {
                            Navigator.pop(context);
                            onShowSensitiveData();
                          },
                        ),
                        const SizedBox(height: 6),
                        _DrawerNavItem(
                          isDark: isDark,
                          icon: Icons.info_outline_rounded,
                          label: 'Acerca de',
                          subtitle: 'VirtualSign LSM · Universidad Politécnica de Chiapas',
                          color: AppColors.accent,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Text(
                            'LEGAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.primary.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _DrawerNavItem(
                          isDark: isDark,
                          icon: Icons.description_outlined,
                          label: 'Términos y Condiciones',
                          subtitle: 'Condiciones de uso del servicio',
                          color: AppColors.violet,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsAndConditionsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        _DrawerNavItem(
                          isDark: isDark,
                          icon: Icons.privacy_tip_outlined,
                          label: 'Política de Privacidad',
                          subtitle: 'Cómo gestionamos tus datos',
                          color: AppColors.accent,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Info badge
                        _DrawerSecurityBadge(isDark: isDark),
                      ],
                    ),
                  ),
                  // ── Botón de cerrar sesión ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: _DrawerLogoutButton(
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        onLogout();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets privados ──────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final bool isDark;
  final String userInitial;
  final String displayName;
  final String email;

  const _DrawerHeader({
    required this.isDark,
    required this.userInitial,
    required this.displayName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Row(
        children: [
          // Avatar clay
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              shape: BoxShape.circle,
              boxShadow: AppClay.shadows(AppColors.primary, isDark: isDark),
            ),
            child: Center(
              child: Text(
                userInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                // Session badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Sesión activa',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Clay icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(isDark ? 0.22 : 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: context.textSecondary.withOpacity(0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerSecurityBadge extends StatelessWidget {
  final bool isDark;

  const _DrawerSecurityBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dispositivo verificado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'RASP activo · Cifrado AES-256',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerLogoutButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerLogoutButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Cerrar sesión',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withOpacity(isDark ? 0.40 : 0.35)),
          backgroundColor: AppColors.error.withOpacity(isDark ? 0.06 : 0.04),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
