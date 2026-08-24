import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize the notification service
  Future<void> initialize() async {
    // Initialize Time Zones
    tz.initializeTimeZones();

    // Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click - could navigate to Due Services
      },
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  // Show immediate notification summarizing due services
  Future<void> showDueServicesSummaryNotification({
    required int todayCount,
    required int overdueCount,
    required int upcomingCount,
  }) async {
    if (todayCount == 0 && overdueCount == 0 && upcomingCount == 0) return;

    final String title = 'RO Service Schedule Update';
    String body = '';
    
    if (overdueCount > 0) {
      body += '⚠️ $overdueCount service(s) OVERDUE!\n';
    }
    if (todayCount > 0) {
      body += '📅 $todayCount service(s) DUE TODAY.\n';
    }
    if (upcomingCount > 0) {
      body += '🔔 $upcomingCount upcoming service(s) soon.';
    }

    body = body.trim();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'meet_electronics_channel_id',
      'Meet Electronics RO Service Alerts',
      channelDescription: 'Notifications for due and overdue RO services',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotificationsPlugin.show(
      0, // ID
      title,
      body,
      notificationDetails,
    );
  }

  // Schedule a daily notification at 9:00 AM to check for due services
  Future<void> scheduleDailyReminder() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'meet_electronics_daily_id',
      'Meet Electronics Daily Reminder',
      channelDescription: 'Daily morning reminder to review due RO services',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Cancel existing daily reminder to avoid duplicates
    await _localNotificationsPlugin.cancel(1);

    // Schedule for 9:00 AM daily
    try {
      await _localNotificationsPlugin.zonedSchedule(
        1,
        'Meet Electronics Morning Check',
        'Check today\'s due and overdue RO services.',
        _nextInstanceOfNineAM(),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint("Daily notification reminder schedule failed: $e");
    }
  }

  // Helper helper to get next instance of 9:00 AM in local timezone
  tz.TZDateTime _nextInstanceOfNineAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
