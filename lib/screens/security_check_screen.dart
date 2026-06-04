import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/security_service.dart';
import '../theme/app_theme.dart';
import '../features/auth/screens/login_screen.dart';

/// Pantalla de seguridad persistente que envuelve al [LoginScreen].
///
/// Monitorea continuamente mediante:
/// - [WidgetsBindingObserver]: detecta cuando el usuario regresa a la app.
/// - [Timer.periodic]: chequeo automático cada [_checkInterval] segundos.
class SecurityCheckScreen extends StatefulWidget {
  const SecurityCheckScreen({super.key});

  @override
  State<SecurityCheckScreen> createState() => _SecurityCheckScreenState();
}

class _SecurityCheckScreenState extends State<SecurityCheckScreen>
    with WidgetsBindingObserver {
  static const _checkInterval = Duration(seconds: 4);

  bool _isChecking = true;
  bool _isDeviceSecure = true;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runSecurityCheck();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runSecurityCheck();
    }
  }

  void _startPeriodicCheck() {
    _periodicTimer = Timer.periodic(_checkInterval, (_) {
      _runSecurityCheck();
    });
  }

  Future<void> _runSecurityCheck() async {
    final result = await SecurityService.checkDeviceSecurity();
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _isDeviceSecure = result.isDeviceSecure;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) return const _LoadingView();
    if (!_isDeviceSecure) {
      return const _BlockedView(
        icon: Icons.gps_off_rounded,
        title: 'Ubicación simulada detectada',
        message:
            'Se detectó una aplicación de Fake GPS activa en este dispositivo.\n\n'
            'Por seguridad, AprendIA no puede ejecutarse mientras haya '
            'una ubicación simulada activa.\n\n'
            'Desactiva el Fake GPS e intenta de nuevo.',
      );
    }
    return const LoginScreen();
  }
}

// ---------------------------------------------------------------------------
// Widgets privados
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 20),
            Text(
              'Verificando seguridad del dispositivo...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _BlockedView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 52, color: AppColors.error),
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7A1A1A),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 16, color: AppColors.error),
                      SizedBox(width: 8),
                      Text(
                        'Protección de seguridad activa',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
