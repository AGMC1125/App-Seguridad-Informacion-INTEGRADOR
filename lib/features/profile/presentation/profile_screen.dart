import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/session_notifier.dart';
import '../../../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Edit profile
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _savingProfile = false;

  // Change password
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _changingPassword = false;
  bool _showCurrentPwd = false;
  bool _showNewPwd = false;
  bool _showConfirmPwd = false;

  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionNotifierProvider);
    _nameCtrl.text = session.userName;
    _emailCtrl.text = session.userEmail;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty && email.isEmpty) return;

    setState(() => _savingProfile = true);
    final error = await ref.read(sessionNotifierProvider.notifier).updateProfile(name: name, email: email);
    if (!mounted) return;
    setState(() => _savingProfile = false);

    if (error == null) {
      _showSnack('Perfil actualizado', AppColors.success);
    } else {
      _showSnack(error, AppColors.error);
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordCtrl.text;
    final newPwd = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (current.isEmpty || newPwd.isEmpty || confirm.isEmpty) {
      _showSnack('Completa todos los campos', AppColors.warning);
      return;
    }
    if (newPwd.length < 8) {
      _showSnack('La nueva contraseña debe tener al menos 8 caracteres', AppColors.warning);
      return;
    }
    if (newPwd != confirm) {
      _showSnack('Las contraseñas no coinciden', AppColors.warning);
      return;
    }

    setState(() => _changingPassword = true);
    final error = await ref.read(sessionNotifierProvider.notifier).changePassword(
      currentPassword: current,
      newPassword: newPwd,
    );
    if (!mounted) return;
    setState(() => _changingPassword = false);

    if (error == null) {
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      _showSnack('Contraseña actualizada', AppColors.success);
    } else {
      _showSnack(error, AppColors.error);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Eliminar cuenta',
            style: TextStyle(color: ctx.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Tu cuenta será desactivada. Esta acción no se puede deshacer.',
          style: TextStyle(color: ctx.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: ctx.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar cuenta', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _deletingAccount = true);
    final error = await ref.read(sessionNotifierProvider.notifier).deleteAccount();
    if (!mounted) return;

    if (error != null) {
      setState(() => _deletingAccount = false);
      _showSnack(error, AppColors.error);
    }
    // Si deleteAccount tuvo éxito el SessionProvider llamó _clearState() y
    // notifyListeners(), por lo que el Navigator raíz redirigirá al login.
  }

  void _showSnack(String msg, Color color) {
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
    final session = ref.watch(sessionNotifierProvider);

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
        title: Text('Mi perfil',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar header
            _buildAvatarHeader(context, session),
            const SizedBox(height: 28),

            // Sección: Editar perfil
            _buildSectionTitle(context, Icons.edit_rounded, 'Editar perfil'),
            const SizedBox(height: 12),
            _buildCard(
              context,
              child: Column(
                children: [
                  _buildTextField(
                    context,
                    controller: _nameCtrl,
                    label: 'Nombre',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    context,
                    controller: _emailCtrl,
                    label: 'Correo electrónico',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildPrimaryButton(
                    context,
                    label: _savingProfile ? 'Guardando…' : 'Guardar cambios',
                    loading: _savingProfile,
                    onTap: _savingProfile ? null : _saveProfile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sección: Cambiar contraseña
            _buildSectionTitle(context, Icons.lock_outline_rounded, 'Cambiar contraseña'),
            const SizedBox(height: 12),
            _buildCard(
              context,
              child: Column(
                children: [
                  _buildPasswordField(
                    context,
                    controller: _currentPasswordCtrl,
                    label: 'Contraseña actual',
                    show: _showCurrentPwd,
                    onToggle: () => setState(() => _showCurrentPwd = !_showCurrentPwd),
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    context,
                    controller: _newPasswordCtrl,
                    label: 'Nueva contraseña (mín. 8 caracteres)',
                    show: _showNewPwd,
                    onToggle: () => setState(() => _showNewPwd = !_showNewPwd),
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    context,
                    controller: _confirmPasswordCtrl,
                    label: 'Confirmar nueva contraseña',
                    show: _showConfirmPwd,
                    onToggle: () => setState(() => _showConfirmPwd = !_showConfirmPwd),
                  ),
                  const SizedBox(height: 16),
                  _buildPrimaryButton(
                    context,
                    label: _changingPassword ? 'Actualizando…' : 'Cambiar contraseña',
                    loading: _changingPassword,
                    onTap: _changingPassword ? null : _changePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sección: Zona de peligro
            _buildSectionTitle(context, Icons.warning_amber_rounded, 'Zona de peligro',
                color: AppColors.error),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Eliminar cuenta',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error)),
                  const SizedBox(height: 6),
                  Text(
                    'Tu cuenta será desactivada permanentemente. No podrás volver a acceder.',
                    style: TextStyle(fontSize: 12, color: context.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deletingAccount ? null : _deleteAccount,
                      icon: _deletingAccount
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                          : const Icon(Icons.delete_forever_rounded, size: 18, color: AppColors.error),
                      label: Text(
                          _deletingAccount ? 'Eliminando…' : 'Eliminar mi cuenta',
                          style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),   // Scaffold
  );     // Container
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildAvatarHeader(BuildContext context, SessionState session) {
    return Row(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Center(
            child: Text(
              session.userName.isNotEmpty ? session.userName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.userName,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
              const SizedBox(height: 3),
              Text(session.userEmail,
                  style: TextStyle(fontSize: 12, color: context.textSecondary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: AppColors.success),
                    const SizedBox(width: 5),
                    Text('Sesión activa', style: TextStyle(fontSize: 10, color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, IconData icon, String title, {Color? color}) {
    final c = color ?? AppColors.primary;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary)),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.2 : 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: context.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: context.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        filled: true,
        fillColor: context.cardVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !show,
      style: TextStyle(fontSize: 14, color: context.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: context.textSecondary),
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 18, color: context.textSecondary),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: context.cardVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
    BuildContext context, {
    required String label,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity, height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(colors: [AppColors.primary, AppColors.accent])
              : null,
          color: onTap == null ? context.dividerColor : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
