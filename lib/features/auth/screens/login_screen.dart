import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../theme/app_theme.dart';
import 'register_screen.dart';

// ─── Particle model ───────────────────────────────────────────────────────────

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

// ─── Floating-particle painter ────────────────────────────────────────────────

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
                ? const Color(0xFF06D6A0)
                : const Color(0xFF4F8EF7))
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

// ─── LoginScreen ──────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Lógica de formulario (SIN CAMBIOS) ───────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ── Estado de visibilidad de contraseña ──────────────────────────────────
  bool _obscurePassword = true;

  // ── Animaciones ──────────────────────────────────────────────────────────
  late final AnimationController _particleCtrl;
  late final AnimationController _pulseCtrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    final rng = math.Random(7);
    _particles = List.generate(24, (i) {
      return _Particle(
        x: rng.nextDouble(),
        baseY: rng.nextDouble(),
        size: rng.nextDouble() * 3 + 1.2,
        speed: rng.nextDouble() * 0.35 + 0.12,
        opacity: rng.nextDouble() * 0.30 + 0.07,
        isTeal: i % 4 == 0,
      );
    });
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Login logic (SIN CAMBIOS) ────────────────────────────────────────────
  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await context.read<SessionProvider>().login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
    // Si error == null, SessionProvider notifica el cambio y
    // main.dart navega automáticamente al HomeScreen.
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1A),
      body: AnimatedBuilder(
        animation: Listenable.merge([_particleCtrl, _pulseCtrl]),
        builder: (context, _) {
          return Stack(
            children: [
              // Fondo degradado
              _buildBackground(),
              // Partículas flotantes
              Positioned.fill(
                child: CustomPaint(
                  painter: _ParticlePainter(_particles, _particleCtrl.value),
                ),
              ),
              // Contenido principal
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      _buildLogo(),
                      const SizedBox(height: 44),
                      _buildFormCard(),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Widgets de UI ─────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.4,
          colors: [
            Color(0xFF0D1B3E),
            Color(0xFF080E1A),
            Color(0xFF04070F),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final pulse = _pulseCtrl.value;

    return Column(
      children: [
        // Glow animado
        Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF4F8EF7), Color(0xFF06D6A0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFF4F8EF7).withOpacity(0.22 + pulse * 0.28),
                blurRadius: 22 + pulse * 22,
                spreadRadius: 1 + pulse * 5,
              ),
              BoxShadow(
                color:
                    const Color(0xFF06D6A0).withOpacity(0.08 + pulse * 0.14),
                blurRadius: 44 + pulse * 28,
                spreadRadius: -6,
              ),
            ],
          ),
          child: const Icon(
            Icons.sign_language_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'AprendIA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(
                color: const Color(0xFF06D6A0).withOpacity(0.35)),
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF06D6A0).withOpacity(0.07),
          ),
          child: const Text(
            'LENGUA DE SEÑAS · CHIAPAS',
            style: TextStyle(
              color: Color(0xFF06D6A0),
              fontSize: 10,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 48,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenido de nuevo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Inicia sesión para continuar aprendiendo',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),

            // ── Correo electrónico (validadores SIN CAMBIOS) ──────────────
            _buildField(
              label: 'Correo electrónico',
              hint: 'ejemplo@correo.com',
              icon: Icons.email_outlined,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu correo';
                }
                if (!value.contains('@')) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Contraseña (validadores SIN CAMBIOS) ─────────────────────
            _buildField(
              label: 'Contraseña',
              hint: 'Mínimo 8 caracteres',
              icon: Icons.lock_outline,
              controller: _passwordController,
              isPassword: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu contraseña';
                }
                if (value.length < 8) {
                  return 'La contraseña debe tener al menos 8 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36)),
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: Color(0xFF4F8EF7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),
            _buildGradientButton(
              text: 'Iniciar sesión',
              isLoading: _isLoading,
              onPressed: _onLogin,
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: Divider(
                        color: Colors.white.withOpacity(0.12))),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'o',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.30),
                        fontSize: 13),
                  ),
                ),
                Expanded(
                    child: Divider(
                        color: Colors.white.withOpacity(0.12))),
              ],
            ),
            const SizedBox(height: 24),

            _buildOutlineButton(
              text: 'Crear cuenta nueva',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const RegisterScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de campos y botones ───────────────────────────────────────────

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
          keyboardType: keyboardType,
          obscureText: isPassword ? _obscurePassword : false,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.25), fontSize: 14),
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            prefixIcon: Icon(icon,
                color: const Color(0xFF4F8EF7), size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withOpacity(0.38),
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.10)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFF4F8EF7), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: AppColors.error, width: 1.5),
            ),
            errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
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
            colors: [Color(0xFF4F8EF7), Color(0xFF06D6A0)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:
                  const Color(0xFF4F8EF7).withOpacity(0.38),
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

  Widget _buildOutlineButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
              color: Colors.white.withOpacity(0.22), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
