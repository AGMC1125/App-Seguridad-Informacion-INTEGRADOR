import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handler para mensajes recibidos con la app en BACKGROUND o TERMINADA.
/// Debe ser una función de nivel superior (fuera de cualquier clase).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Notificación en background: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Canal de notificaciones para Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'aprendia_channel', // id
    'Notificaciones AprendIA', // nombre visible
    description: 'Canal principal de notificaciones de AprendIA',
    importance: Importance.high,
  );

  /// Inicializa Firebase Messaging y notificaciones locales.
  /// Llama esto desde main() después de Firebase.initializeApp().
  Future<void> initialize() async {
    // Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Pedir permisos (necesario en iOS y Android 13+)
    await _requestPermissions();

    // Configurar notificaciones locales
    await _initLocalNotifications();

    // Escuchar mensajes en FOREGROUND
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Manejar tap en notificación cuando la app estaba en BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Verificar si la app fue abierta desde una notificación (app TERMINADA)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Mostrar el FCM token en consola (útil para pruebas)
    final token = await _messaging.getToken();
    debugPrint('🔑 FCM Token: $token');
  }

  /// Solicita permisos de notificación al usuario.
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      // Android 13+ — el permiso POST_NOTIFICATIONS se pide en runtime
      await _messaging.requestPermission();
    }
  }

  /// Configura flutter_local_notifications para mostrar notificaciones
  /// mientras la app está en foreground.
  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Tap en notificación local: ${details.payload}');
        // Aquí puedes navegar a una pantalla específica según el payload
      },
    );

    // Crear el canal en Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Muestra una notificación local cuando el mensaje llega en FOREGROUND.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📬 Mensaje en foreground: ${message.notification?.title}');

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

  /// Maneja el tap en una notificación (background / terminated).
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Usuario tocó notificación: ${message.notification?.title}');
    // TODO: navega a la pantalla correspondiente usando el data del mensaje
    // Ejemplo: navigatorKey.currentState?.pushNamed('/detalle');
  }

  /// Devuelve el token FCM actual del dispositivo.
  Future<String?> getToken() => _messaging.getToken();

  /// Suscribe al dispositivo a un topic (ej. "noticias", "alertas").
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  /// Cancela la suscripción a un topic.
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);
}
