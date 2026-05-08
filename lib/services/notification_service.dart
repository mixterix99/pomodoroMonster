import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ); // Usa el icono de tu app

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      // 1. Pide permiso para las notificaciones (El Pop-up)
      await androidImplementation.requestNotificationsPermission();

      // 2. Pide permiso para las alarmas exactas (Vital para que el timer suene bloqueado)
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleNotification(
    int seconds,
    String title,
    String body,
  ) async {
    // Definimos el canal de Android (importante para la vibración)
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'focus_monster_channel_v2',
      'Alertas de Enfoque',
      importance: Importance.max,
      priority: Priority.high,
      vibrationPattern: Int64List.fromList([
        0,
        1000,
        500,
        1000,
      ]), // Vibración personalizada
      enableVibration: true,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode
          .exactAllowWhileIdle, // Clave para que suene bloqueado
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
