import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/encrypted_storage_service.dart';
import 'core/services/security_service.dart';
import 'core/services/session_service.dart';
import 'features/auth/presentation/providers/session_notifier.dart';
import 'theme/app_theme.dart';

/// Raíz de la aplicación Flutter con gestión de ciclo de vida.
///
/// Responsabilidades:
/// 1. Configurar [MaterialApp] con tema y modo oscuro.
/// 2. Delegar la decisión de qué pantalla mostrar a [SessionGuard].
/// 3. Gestionar el ciclo de vida de la app vía [WidgetsBindingObserver]:
///    - [paused]   → persistir timestamp de última actividad (AES-256).
///    - [resumed]  → verificar si la sesión expiró en background + RASP re-check.
///    - [inactive] → registrar actividad para extender el timer si el usuario
///                   recibe una llamada o abre el panel de notificaciones.
///
/// Este observer complementa (no reemplaza) el [WidgetsBindingObserver] que
/// ya existe en [SecurityCheckScreen] — cada uno tiene responsabilidad única:
/// - [SecurityCheckScreen] → verificaciones RASP en la pantalla de login.
/// - [AprendIAApp]         → gestión de sesión y RASP mientras el usuario
///                           está autenticado y usa la app.
class AprendIAApp extends ConsumerStatefulWidget {
  const AprendIAApp({super.key});

  @override
  ConsumerState<AprendIAApp> createState() => _AprendIAAppState();
}

class _AprendIAAppState extends ConsumerState<AprendIAApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // El usuario minimizó la app (Android: botón Home / pantalla apagada).
        // Persistimos el timestamp de actividad para que al volver podamos
        // calcular cuánto tiempo estuvo la app en background.
        _onAppPaused();

      case AppLifecycleState.inactive:
        // Transición breve (llamada entrante, panel de notificaciones, etc.).
        // Registramos actividad para que el timer de inactividad se reinicie
        // cuando el usuario regrese, sin cerrar la sesión por una interrupción
        // momentánea que no implica abandono.
        _onAppInactive();

      case AppLifecycleState.resumed:
        // El usuario regresó a la app.
        // 1) Verificar si la sesión expiró mientras estuvo en background.
        // 2) Re-ejecutar verificaciones RASP (el usuario pudo activar ADB
        //    o un Fake GPS mientras la app estaba minimizada).
        _onAppResumed();

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Estados de terminación o visibilidad parcial — sin acción requerida.
        break;
    }
  }

  // ── Handlers privados ─────────────────────────────────────────────────────

  /// Llamado cuando el usuario minimiza la app.
  ///
  /// Solo actúa si hay una sesión activa — no tiene sentido guardar
  /// actividad si el usuario no está autenticado.
  void _onAppPaused() {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isLoggedIn) return;

    // Persiste el timestamp actual en almacenamiento AES-256.
    // SessionService.registerActivity() llama internamente a
    // _persistLastActivity() que escribe en EncryptedStorageService.
    if (SessionService.instance.isRunning) {
      SessionService.instance.registerActivity();
    }
  }

  /// Llamado en transiciones momentáneas (llamada, panel de notificaciones).
  ///
  /// Registra actividad para evitar que el timer de inactividad expire
  /// durante una interrupción breve no iniciada por el usuario.
  void _onAppInactive() {
    final session = ref.read(sessionNotifierProvider);
    if (!session.isLoggedIn) return;
    if (SessionService.instance.isRunning) {
      SessionService.instance.registerActivity();
    }
  }

  /// Llamado cuando el usuario regresa a la app.
  ///
  /// Ejecuta dos verificaciones en paralelo:
  /// 1. Expiración de sesión en background.
  /// 2. Re-check RASP (Fake GPS / USB Debugging).
  Future<void> _onAppResumed() async {
    final session = ref.read(sessionNotifierProvider);

    // ── 1. Verificar expiración de sesión en background ───────────────────
    if (session.isLoggedIn) {
      await _checkBackgroundSessionExpiry();
    }

    // ── 2. RASP re-check mientras hay sesión activa ───────────────────────
    // (El RASP del login ya lo maneja SecurityCheckScreen;
    //  aquí protegemos a usuarios ya autenticados contra amenazas
    //  activadas mientras la app estaba minimizada.)
    if (session.isLoggedIn) {
      await _checkRasp();
    }
  }

  /// Verifica si la sesión expiró mientras la app estuvo en background.
  ///
  /// Lee el timestamp de última actividad del almacén AES-256 y compara
  /// contra [AppConstants.sessionTimeout]. Si la diferencia supera el timeout
  /// y el usuario está autenticado, cierra la sesión automáticamente.
  Future<void> _checkBackgroundSessionExpiry() async {
    try {
      final raw = await EncryptedStorageService.read(
        key: AppConstants.storageKeyLastActivity,
      );
      if (raw == null) return;

      final lastActivity = DateTime.tryParse(raw);
      if (lastActivity == null) return;

      final elapsed = DateTime.now().difference(lastActivity);
      if (elapsed > AppConstants.sessionTimeout) {
        // La sesión expiró en background — cerrar sin confirmación.
        await ref.read(sessionNotifierProvider.notifier).logout();
      }
    } catch (_) {
      // Fallo silencioso: si no podemos leer el timestamp, no forzamos
      // el cierre — el timer de inactividad activo seguirá funcionando.
    }
  }

  /// Re-ejecuta las verificaciones RASP después de que el usuario regresa.
  ///
  /// Si el dispositivo ya no es seguro (Fake GPS / USB Debugging activo),
  /// cierra la sesión para proteger los datos del usuario autenticado.
  /// La pantalla de bloqueo ya mostrará el estado inseguro via [SecurityCheckScreen].
  Future<void> _checkRasp() async {
    try {
      final result = await SecurityService.checkDeviceSecurity();
      if (!result.isDeviceSecure) {
        // Dispositivo inseguro detectado post-login → forzar logout.
        await ref.read(sessionNotifierProvider.notifier).logout();
      }
    } catch (_) {
      // RASP no disponible en esta plataforma — fallo silencioso.
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'VirtualSign LSM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
