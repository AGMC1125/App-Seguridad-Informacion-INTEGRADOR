import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/auth_status.dart';
import '../providers/session_notifier.dart';

// ─── Particle painter (reutilizado del login) ─────────────────────────────────

class _Particle {
  final double x;
  final double baseY;
  final double size;
  final double speed;
  final double opacity;
  final bool isTeal;

  const _Particle({
    required this.x,
    required this.baseY,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.isTeal,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  const _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final raw = (p.baseY - t * p.speed) % 1.0;
      final y = raw < 0 ? raw + 1.0 : raw;
      final paint = Paint()
        ..color = (p.isTeal
                ? AppColors.accent
                : AppColors.primary)
            .withOpacity(p.opacity);
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

// ─── RegisterScreen ───────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  // ── Lógica del formulario ─────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // _isLoading eliminado — el estado de carga viene de SessionState.authStatus
  bool _acceptTerms = false;
  late final TapGestureRecognizer _privacyTapRecognizer;
  late final TapGestureRecognizer _termsTapRecognizer;

  // ── Estado de visibilidad de contraseñas ─────────────────────────────────
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ── Focus nodes para navegación con teclado ──────────────────────────────
  final _nameFocus    = FocusNode();
  final _emailFocus   = FocusNode();
  final _passFocus    = FocusNode();
  final _confirmFocus = FocusNode();

  // ── Animaciones ──────────────────────────────────────────────────────────
  late final AnimationController _particleCtrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _privacyTapRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(RouteNames.privacy);

    _termsTapRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push(RouteNames.terms);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    final rng = math.Random(13);
    _particles = List.generate(20, (i) {
      return _Particle(
        x: rng.nextDouble(),
        baseY: rng.nextDouble(),
        size: rng.nextDouble() * 2.5 + 1.0,
        speed: rng.nextDouble() * 0.30 + 0.10,
        opacity: rng.nextDouble() * 0.25 + 0.06,
        isTeal: i % 5 == 0,
      );
    });
  }

  @override
  void dispose() {
    _privacyTapRecognizer.dispose();
    _termsTapRecognizer.dispose();
    _particleCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    // Limpiar authStatus para no dejar estado residual al salir de la pantalla
    ref.read(sessionNotifierProvider.notifier).clearAuthStatus();
    super.dispose();
  }

  // ── Lógica de registro ───────────────────────────────────────────────────
  void _onRegister() async {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    // SessionNotifier emite loading → success | error en SessionState.authStatus
    // El widget reacciona vía ref.watch (spinner) y ref.listen (snackbar + pop)
    await ref.read(sessionNotifierProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Efectos secundarios: snackbar de error y navegación al éxito
    ref.listen<SessionState>(sessionNotifierProvider, (prev, next) {
      if (next.authStatus == AuthStatus.error && next.authError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.authError!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      if (next.authStatus == AuthStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada exitosamente!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    });

    // El widget observa el estado — sin lógica de negocio aquí
    final isLoading =
        ref.watch(sessionNotifierProvider).authStatus == AuthStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      body: AnimatedBuilder(
        animation: _particleCtrl,
        builder: (context, _) {
          return Stack(
            children: [
              // Fondo
              _buildBackground(),
              // Partículas
              Positioned.fill(
                child: CustomPaint(
                  painter:
                      _ParticlePainter(_particles, _particleCtrl.value),
                ),
              ),
              // Contenido
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildHeader(),
                            const SizedBox(height: 28),
                            _buildFormCard(isLoading),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF060918), Color(0xFF030810), Color(0xFF08051A)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        const Positioned(
          top: -50, left: -60,
          child: AppBlob(size: 260, color: AppColors.violet, opacity: 0.09),
        ),
        const Positioned(
          bottom: 60, right: -50,
          child: AppBlob(size: 280, color: AppColors.primary, opacity: 0.08),
        ),
        const Positioned(
          top: 180, left: 30,
          child: AppBlob(size: 140, color: AppColors.accent, opacity: 0.06),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Botón regresar
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const Spacer(),
          // Indicador de pasos (estético)
          Row(
            children: List.generate(4, (i) {
              final isActive = i == 0;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.accent
                          ],
                        )
                      : null,
                  color: isActive
                      ? null
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.person_add_rounded,
              color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crear cuenta',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Únete y comienza a aprender LSM',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isLoading) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 48,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.violet.withOpacity(0.06),
                blurRadius: 32,
                offset: const Offset(0, 4),
              ),
            ],
          ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Nombre completo (validadores SIN CAMBIOS) ─────────────────
            _buildField(
              label: 'Nombre completo',
              hint: 'Ej. Juan Pérez',
              icon: Icons.person_outline,
              controller: _nameController,
              focusNode: _nameFocus,
              nextFocusNode: _emailFocus,
              textInputAction: TextInputAction.next,
              validator: Validators.name,
            ),
            const SizedBox(height: 16),

            // ── Correo electrónico (validación centralizada) ─────────────
            _buildField(
              label: 'Correo electrónico',
              hint: 'ejemplo@correo.com',
              icon: Icons.email_outlined,
              controller: _emailController,
              focusNode: _emailFocus,
              nextFocusNode: _passFocus,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),

            // ── Contraseña (validación centralizada) ─────────────────────
            _buildField(
              label: 'Contraseña',
              hint: 'Mínimo 8 caracteres',
              icon: Icons.lock_outline,
              controller: _passwordController,
              focusNode: _passFocus,
              nextFocusNode: _confirmFocus,
              textInputAction: TextInputAction.next,
              isPassword: true,
              obscureValue: _obscurePassword,
              onToggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              validator: Validators.passwordStrength,
            ),
            const SizedBox(height: 16),

            // ── Confirmar contraseña (validación centralizada) ───────────
            _buildField(
              label: 'Confirmar contraseña',
              hint: 'Repite tu contraseña',
              icon: Icons.lock_outline,
              controller: _confirmPasswordController,
              focusNode: _confirmFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: _onRegister,
              isPassword: true,
              obscureValue: _obscureConfirm,
              onToggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (value) =>
                  Validators.confirmPassword(value, _passwordController.text),
            ),
            const SizedBox(height: 20),

            // ── Términos y condiciones (lógica SIN CAMBIOS) ───────────────
            _buildTermsRow(),
            const SizedBox(height: 26),

            // ── Botón crear cuenta ────────────────────────────────────────
            _buildGradientButton(
              text: 'Crear cuenta',
              isLoading: isLoading,
              onPressed: _onRegister,
            ),
            const SizedBox(height: 20),

            // ── Ya tengo cuenta (SIN CAMBIOS) ─────────────────────────────
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: RichText(
                  text: TextSpan(
                    text: '¿Ya tienes cuenta? ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.40),
                      fontSize: 13,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Inicia sesión',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _acceptTerms = !_acceptTerms),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: _acceptTerms
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    )
                  : null,
              color: _acceptTerms
                  ? null
                  : Colors.white.withOpacity(0.08),
              border: Border.all(
                color: _acceptTerms
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.20),
              ),
            ),
            child: _acceptTerms
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: 'Acepto los ',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 13),
              children: [
                TextSpan(
                  text: 'Términos y condiciones',
                  recognizer: _termsTapRecognizer,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
                const TextSpan(text: ' y la '),
                TextSpan(
                  text: 'Política de privacidad',
                  recognizer: _privacyTapRecognizer,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureValue = true,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: isPassword ? obscureValue : false,
          validator: validator,
          onFieldSubmitted: (_) {
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            } else {
              onSubmitted?.call();
            }
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.25), fontSize: 14),
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            prefixIcon:
                Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureValue
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withOpacity(0.38),
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: AppColors.error, width: 1.5),
            ),
            errorStyle:
                const TextStyle(color: Color(0xFFFF6B6B)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.38),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
