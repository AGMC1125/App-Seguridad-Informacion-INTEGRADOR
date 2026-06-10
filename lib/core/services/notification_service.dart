import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'sensitive_data_service.dart';

/// Handler para mensajes recibidos con la app en BACKGROUND o TERMINADA.
/// Debe ser una función de nivel superior (fuera de cualquier clase).
///
/// Si el mensaje es de tipo "remote_wipe" y el correo objetivo coincide
/// con el almacenado en el dispositivo, se eliminan todos los datos sensibles.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Notificación en background: ${message.data}');

  if (message.data['type'] == 'remote_wipe') {
    final targetEmail = message.data['target_email'] ?? '';
    final storedEmail = await SensitiveDataService.getStoredEmail();

    if (storedEmail != null &&
        storedEmail.isNotEmpty &&
        storedEmail == targetEmail) {
      await SensitiveDataService.wipeAll();
      debugPrint('🗑️ Borrado remoto ejecutado (background) para: $targetEmail');
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Canal de notificaciones para Android.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'aprendia_channel',
    'Notificaciones AprendIA',
    description: 'Canal principal de notificaciones de AprendIA',
    importance: Importance.high,
  );

  /// Callback que se invoca cuando llega una orden de borrado remoto
  /// con la app en FOREGROUND. Lo asigna [SessionProvider] al iniciar sesión.
  static void Function(String targetEmail)? onRemoteWipe;

  /// Inicializa Firebase Messaging y notificaciones locales.
  /// Si el emulador no tiene Google Play Services disponible, la app
  /// continúa funcionando sin FCM (solo sin notificaciones push).
  Future<void> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _requestPermissions();
      await _initLocalNotifications();
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      try {
        final token = await _messaging.getToken();
        debugPrint('🔑 FCM Token: $token');
      } catch (e) {
        // En emuladores sin Google Play Services el token no está disponible.
        // La app funciona normalmente; FCM solo actúa en dispositivos reales.
        debugPrint('⚠️ FCM token no disponible (emulador sin Play Services): $e');
      }
    } catch (e) {
      debugPrint('⚠️ Error inicializando FCM, continuando sin notificaciones: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      await _messaging.requestPermission();
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Tap en notificación local: ${details.payload}');
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Maneja mensajes cuando la app está en FOREGROUND.
  /// Si el tipo es "remote_wipe", invoca el callback de borrado en lugar
  /// de mostrar una notificación visible.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Mensaje foreground: ${message.data}');

    if (message.data['type'] == 'remote_wipe') {
      final targetEmail = message.data['target_email'] ?? '';
      debugPrint('🗑️ Orden de borrado remoto recibida para: $targetEmail');
      onRemoteWipe?.call(targetEmail);
      return;
    }

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data.toString(),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Usuario tocó notificación: ${message.notification?.title}');
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);
}
