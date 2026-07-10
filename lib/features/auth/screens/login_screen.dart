import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../theme/app_theme.dart';
import 'register_screen.dart';

// ─── LoginScreen ──────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── Lógica de formulario (SIN CAMBIOS) ───────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ── Estado de visibilidad de contraseña ──────────────────────────────────
  bool _obscurePassword = true;

  // ── Focus nodes para navegación con teclado ──────────────────────────────
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
      body: Stack(
        children: [
          // Fondo degradado estático
          _buildBackground(),
          // Contenido principal — no scrolleable, ocupa toda la pantalla
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _buildLogo(),
                  const Spacer(flex: 2),
                  _buildFormCard(),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets de UI ─────────────────────────────────────────────────────────

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
          top: -60, right: -40,
          child: AppBlob(size: 280, color: AppColors.primary, opacity: 0.10),
        ),
        const Positioned(
          bottom: 80, left: -60,
          child: AppBlob(size: 300, color: AppColors.violet, opacity: 0.08),
        ),
        const Positioned(
          top: 200, right: 30,
          child: AppBlob(size: 160, color: AppColors.accent, opacity: 0.06),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Logo de la app con sombra estática
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F8EF7).withOpacity(0.30),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF06D6A0).withOpacity(0.12),
                blurRadius: 48,
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/images/logo-app.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'VirtualSign LSM',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(
                color: const Color(0xFF06D6A0).withOpacity(0.35)),
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF06D6A0).withOpacity(0.07),
          ),
          child: const Text(
            'LENGUA DE SEÑAS MEXICANA',
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 48,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.primary.withOpacity(0.06),
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
            const SizedBox(height: 20),

            // ── Correo electrónico (validadores SIN CAMBIOS) ──────────────
            _buildField(
              label: 'Correo electrónico',
              hint: 'ejemplo@correo.com',
              icon: Icons.email_outlined,
              controller: _emailController,
              focusNode: _emailFocus,
              nextFocusNode: _passwordFocus,
              textInputAction: TextInputAction.next,
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
              focusNode: _passwordFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: _onLogin,
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

            const SizedBox(height: 14),
            _buildGradientButton(
              text: 'Iniciar sesión',
              isLoading: _isLoading,
              onPressed: _onLogin,
            ),

            const SizedBox(height: 16),
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
            const SizedBox(height: 16),

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
        ), // Container
      ), // BackdropFilter
    ); // ClipRRect
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
          obscureText: isPassword ? _obscurePassword : false,
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
