import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// Resultado de la verificación de seguridad del dispositivo.
class SecurityCheckResult {
  final bool isMockLocationActive;
  final String? errorMessage;

  const SecurityCheckResult({
    required this.isMockLocationActive,
    this.errorMessage,
  });

  /// El dispositivo es seguro si no hay Fake GPS activo.
  bool get isDeviceSecure => !isMockLocationActive;
}

/// Servicio centralizado para todas las verificaciones de seguridad del dispositivo.
///
/// Al estar separado de la UI, puede reutilizarse desde cualquier pantalla
/// o servicio sin duplicar lógica.
class SecurityService {
  // Constructor privado: esta clase no necesita instanciarse.
  SecurityService._();

  /// Canal nativo hacia Kotlin para consultar ajustes del sistema que no
  /// están expuestos por ningún plugin de Flutter (ej. ADB_ENABLED).
  static const MethodChannel _securityChannel =
      MethodChannel('com.aprendia.aprendia/security');

  /// Consulta a la capa nativa de Android si la Depuración USB está activa,
  /// leyendo `Settings.Global.ADB_ENABLED` desde [MainActivity].
  ///
  /// Retorna `false` ante cualquier error de plataforma (ej. ejecutando en
  /// iOS, donde el canal no existe) para no bloquear el acceso por error.
  static Future<bool> isUsbDebuggingEnabled() async {
    try {
      final bool enabled =
          await _securityChannel.invokeMethod<bool>('isAdbEnabled') ?? false;
      return enabled;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Verifica si el dispositivo tiene alguna amenaza de seguridad activa.
  ///
  /// Detecta ubicación simulada (Fake GPS / Mock Location) usando la API
  /// nativa de Android a través de [Geolocator], que verifica
  /// [Position.isMocked] — confiable en Android 6+.
  ///
  /// Retorna un [SecurityCheckResult] con el detalle del resultado.
  static Future<SecurityCheckResult> checkDeviceSecurity() async {
    try {
      // 1. Verificar y solicitar permiso de ubicación si hace falta
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) {
        // Sin permiso no podemos verificar; permitimos el acceso
        return const SecurityCheckResult(isMockLocationActive: false);
      }

      // 2. Obtener posición actual — si hay Fake GPS activo, responde
      //    casi de inmediato porque el proveedor mock ya tiene coordenadas.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // 3. isMocked = true cuando la posición proviene de un proveedor
      //    simulado (mock provider), independientemente de la ubicación
      //    reportada.
      return SecurityCheckResult(isMockLocationActive: position.isMocked);
    } on TimeoutException {
      // No se pudo obtener ubicación en tiempo — permitimos el acceso
      return const SecurityCheckResult(isMockLocationActive: false);
    } catch (e) {
      // Error inesperado — permitimos el acceso y registramos el motivo
      return SecurityCheckResult(
        isMockLocationActive: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Solicita permiso de ubicación si aún no está concedido.
  /// Retorna [true] si el permiso está disponible, [false] en caso contrario.
  static Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
