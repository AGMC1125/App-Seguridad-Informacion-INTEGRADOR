import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/services/security_service.dart';
import '../theme/app_theme.dart';
import '../features/auth/presentation/screens/login_screen.dart';

/// Pantalla de seguridad persistente que envuelve al [LoginScreen].
///
/// Monitorea continuamente mediante:
/// - [WidgetsBindingObserver]: detecta cuando el usuario regresa a la app.
/// - [Timer.periodic]: chequeo automático cada [_checkInterval] segundos.
///
/// Verificaciones RASP activas:
///   1. Fake GPS / Mock Location
///   2. USB Debugging activo (C2-A4) — solo en modo Release/Profile
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
  SecurityCheckResult? _lastResult;
  Timer? _periodicTimer;

  // Control para no mostrar el diálogo de USB Debugging más de una vez.
  bool _usbDialogShown = false;

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
    // Re-verificar al volver a primer plano (el usuario pudo activar/desactivar ADB).
    if (state == AppLifecycleState.resumed) {
      _usbDialogShown = false; // Permitir que el diálogo vuelva a mostrarse.
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
      _lastResult = result;
    });

    // Mostrar el diálogo de bloqueo por USB Debugging si aplica.
    // Se hace en un postFrameCallback para garantizar que el árbol
    // de widgets ya esté montado antes de llamar a showDialog.
    if (!result.isDeviceSecure && result.isUsbDebuggingEnabled && !_usbDialogShown) {
      _usbDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showUsbDebuggingBlockedDialog();
      });
    }
  }

  /// Muestra un [AlertDialog] persistente y no descartable que informa al
  /// usuario del bloqueo por política de seguridad RASP.
  ///
  /// - [barrierDismissible: false] → no se cierra al tocar fuera.
  /// - El único botón cierra la aplicación completamente de forma limpia.
  void _showUsbDebuggingBlockedDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // No descartable: el usuario NO puede ignorarlo.
      builder: (BuildContext dialogContext) {
        return PopScope(
          // Previene que el botón físico "Atrás" cierre el diálogo.
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(
              Icons.usb_off_rounded,
              color: AppColors.error,
              size: 48,
            ),
            title: const Text(
              'Entorno Inseguro Detectado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
                fontSize: 18,
              ),
            ),
            content: const Text(
              'La Depuración USB (USB Debugging) está activa en este dispositivo.\n\n'
              'Por políticas de seguridad de AprendIA, la aplicación no puede '
              'ejecutarse en un entorno de depuración activo, ya que permite '
              'el acceso no autorizado a la memoria y los datos de la aplicación.\n\n'
              'Para continuar, desactiva la Depuración USB en:\n'
              'Ajustes → Opciones de desarrollador → Depuración USB.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.close_rounded),
                label: const Text(
                  'Entendido — Cerrar aplicación',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  // Cerrar la aplicación de forma limpia.
                  exit(0);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) return const _LoadingView();

    // Si USB Debugging está activo, mostramos el Login bloqueado detrás del diálogo
    // (el diálogo es modal y cubre todo — el usuario solo puede cerrar la app).
    if (_lastResult != null && _lastResult!.isUsbDebuggingEnabled) {
      return const _BlockedView(
        icon: Icons.usb_off_rounded,
        title: 'Depuración USB Activa',
        message:
            'La Depuración USB está activa en este dispositivo.\n\n'
            'Por políticas de seguridad, AprendIA no puede ejecutarse '
            'en un entorno de depuración activo.\n\n'
            'Desactiva la Depuración USB en Ajustes → Opciones de desarrollador.',
      );
    }

    if (_lastResult != null && _lastResult!.isMockLocationActive) {
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
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.dark),
      child: Stack(
        children: [
          const Positioned(
            top: -60, right: -40,
            child: AppBlob(size: 200, color: AppColors.primary, opacity: 0.09),
          ),
          const Positioned(
            bottom: 80, left: -60,
            child: AppBlob(size: 240, color: AppColors.violet, opacity: 0.07),
          ),
          const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 20),
                  Text(
                    'Verificando seguridad del dispositivo...',
                    style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0606), Color(0xFF0F0303), Color(0xFF180508)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80, right: -40,
            child: AppBlob(size: 260, color: AppColors.error, opacity: 0.10),
          ),
          Positioned(
            bottom: 60, left: -60,
            child: AppBlob(size: 220, color: const Color(0xFFB91C1C), opacity: 0.07),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.18),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.12),
                              blurRadius: 32,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                 
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.15),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.error.withOpacity(0.30),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
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
                                color: Color(0xFFFC8181),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFFCA5A5),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.error.withOpacity(0.35)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield_outlined,
                                      size: 16, color: Color(0xFFFC8181)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Protección de seguridad activa',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFFC8181),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
