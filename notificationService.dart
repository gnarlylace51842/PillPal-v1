import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Function(String)? onNotificationTap;

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        print('=== NOTIFICATION TAPPED ===');
        print('Payload received: ${response.payload}');
        if (response.payload != null && response.payload!.isNotEmpty) {
          print('Calling onNotificationTap callback');
          onNotificationTap?.call(response.payload!);
        } else {
          print('Payload was null or empty!');
        }
      },
    );

    final launchDetails = await _notifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        onNotificationTap?.call(payload);
      }
    }
  }

  Future<bool> requestPermissions() async {
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final result = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return result ?? false;
  }

  Future<void> scheduleMedicationReminders({
    required String medicationId,
    required String medicationName,
    required DateTime startDate,
    DateTime? endDate,
    int? intervalHours,
    String? scheduleType,
    List<String>? specificTimes,
  }) async {
    await cancelMedicationReminders(medicationId);

    final now = DateTime.now();
    int notificationId = medicationId.hashCode.abs();

    if (scheduleType == 'Interval' && intervalHours != null) {
      final timesPerDay = (24 / intervalHours).round();

      for (int i = 0; i < timesPerDay; i++) {
        final hour = (i * intervalHours) % 24;
        var scheduleTime = DateTime(now.year, now.month, now.day, hour, 0);

        if (scheduleTime.isBefore(now)) {
          scheduleTime = scheduleTime.add(const Duration(days: 1));
        }

        await _scheduleNotification(
          id: notificationId + i,
          title: 'Medication Reminder',
          body: 'Time to take your $medicationName',
          scheduledTime: scheduleTime,
          payload: medicationId,
        );
      }
    } else if (scheduleType == 'Time-based' && specificTimes != null) {
      int index = 0;
      for (final timeStr in specificTimes) {
        final time = _parseTime(timeStr.trim());
        if (time != null) {
          var scheduleTime = DateTime(
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          );

          if (scheduleTime.isBefore(now)) {
            scheduleTime = scheduleTime.add(const Duration(days: 1));
          }

          await _scheduleNotification(
            id: notificationId + index,
            title: 'Medication Reminder',
            body: 'Time to take your $medicationName',
            scheduledTime: scheduleTime,
            payload: medicationId,
          );

          index++;
        }
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    print('Scheduling notification ID: $id with payload: "$payload"');

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Reminders to take your medications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    print('Notification scheduled successfully');
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      final cleaned = timeStr.toUpperCase().trim();
      final isPM = cleaned.contains('PM');
      final isAM = cleaned.contains('AM');

      final timeOnly = cleaned.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = timeOnly.split(':');
      if (parts.length != 2) return null;

      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  Future<void> cancelMedicationReminders(String medicationId) async {
    final baseId = medicationId.hashCode.abs();
    for (int i = 0; i < 24; i++) {
      await _notifications.cancel(baseId + i);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
