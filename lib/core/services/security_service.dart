import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// Resultado de la verificación de seguridad del dispositivo.
class SecurityCheckResult {
  final bool isMockLocationActive;
  final bool isUsbDebuggingEnabled;
  final String? errorMessage;

  const SecurityCheckResult({
    required this.isMockLocationActive,
    required this.isUsbDebuggingEnabled,
    this.errorMessage,
  });

  /// El dispositivo es seguro si no hay Fake GPS ni USB Debugging activo.
  bool get isDeviceSecure => !isMockLocationActive && !isUsbDebuggingEnabled;
}

/// Servicio centralizado para todas las verificaciones RASP del dispositivo.
///
/// Verificaciones implementadas:
///   1. Fake GPS / Mock Location  → via [Geolocator] (Position.isMocked)
///   2. USB Debugging activo      → via MethodChannel → Settings.Global.ADB_ENABLED
///
/// La verificación de USB Debugging solo se aplica fuera de [kDebugMode]
/// para no bloquear el flujo de desarrollo local.
class SecurityService {
  SecurityService._();

  /// Canal de comunicación con el código nativo de Android (Kotlin).
  /// Nombre debe coincidir exactamente con el registrado en [MainActivity].
  static const _channel = MethodChannel('com.aprendia.aprendia/security');

  /// Verifica si el dispositivo tiene alguna amenaza de seguridad activa.
  /// Retorna un [SecurityCheckResult] con el detalle de cada verificación.
  static Future<SecurityCheckResult> checkDeviceSecurity() async {
    final mockLocation = await _checkMockLocation();
    final usbDebugging = await _checkUsbDebugging();

    return SecurityCheckResult(
      isMockLocationActive: mockLocation,
      isUsbDebuggingEnabled: usbDebugging,
    );
  }

  // ---------------------------------------------------------------------------
  // Verificación 1: Fake GPS / Mock Location
  // ---------------------------------------------------------------------------

  /// Detecta ubicación simulada via [Geolocator] (Position.isMocked).
  /// Confiable en Android 6+. Retorna `false` si no se puede verificar.
  static Future<bool> _checkMockLocation() async {
    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) return false;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return position.isMocked;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // ---------------------------------------------------------------------------
  // Verificación 2: USB Debugging (RASP – C2-A4)
  // ---------------------------------------------------------------------------

  /// Consulta [Settings.Global.ADB_ENABLED] vía MethodChannel.
  ///
  /// IMPORTANTE: en [kDebugMode] siempre retorna `false` para no bloquear
  /// el flujo de desarrollo local (el emulador/dispositivo de desarrollo
  /// siempre tiene USB Debugging activo por diseño).
  ///
  /// La restricción aplica estrictamente en modo Release / Profile,
  /// simulando el entorno de producción.
  static Future<bool> _checkUsbDebugging() async {
    // Excepción de desarrollo: no aplicar restricción en debug ni profile local.
    // kProfileMode se usa para análisis de rendimiento con DevTools.
    if (kDebugMode || kProfileMode) return false;

    try {
      final bool isEnabled =
          await _channel.invokeMethod('isUsbDebuggingEnabled');
      return isEnabled;
    } on PlatformException catch (e) {
      // Canal no disponible (iOS, web, desktop) — no aplicar restricción.
      debugPrint('⚠️ SecurityService: USB check no disponible: ${e.message}');
      return false;
    } catch (_) {
      return false;
    }
  }
}
