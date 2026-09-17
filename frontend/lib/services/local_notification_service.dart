import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initializes timezone & local notification plugin settings for Android and iOS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      } catch (_) {}

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[LOCAL_NOTIF_TAP] Notification tapped with payload: ${response.payload}');
        },
      );

      // Create high-importance Android Notification Channel
      const androidChannel = AndroidNotificationChannel(
        'bpace_ritual_reminders',
        'BPACE 호흡 리추얼 알림',
        description: '일정 30분 전 맞춤 호흡 안내 알림',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.createNotificationChannel(androidChannel);

      if (!kIsWeb) {
        try {
          await androidImplementation?.requestNotificationsPermission();
        } catch (_) {}
      }

      _isInitialized = true;
      debugPrint('[LOCAL_NOTIF_INIT] LocalNotificationService initialized successfully.');
    } catch (e) {
      debugPrint('[LOCAL_NOTIF_INIT_ERROR] $e');
    }
  }

  /// Schedules a 30-minute advance local push notification for a schedule.
  Future<void> schedule30MinReminder({
    required String id,
    required String title,
    required DateTime scheduleDate,
    required String timeStr,
  }) async {
    await initialize();

    try {
      final scheduledDateTime = _parseScheduleDateTime(scheduleDate, timeStr);
      if (scheduledDateTime == null) return;

      // 30 minutes prior to schedule
      final reminderTime = scheduledDateTime.subtract(const Duration(minutes: 30));
      final now = DateTime.now();

      if (reminderTime.isBefore(now)) {
        debugPrint('[LOCAL_NOTIF_SKIP] Reminder time $reminderTime for "$title" is in the past.');
        return;
      }

      final notificationId = id.hashCode.abs() % 100000;

      const androidDetails = AndroidNotificationDetails(
        'bpace_ritual_reminders',
        'BPACE 호흡 리추얼 알림',
        channelDescription: '일정 30분 전 맞춤 호흡 안내 알림',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);

      try {
        await _plugin.zonedSchedule(
          notificationId,
          '[일정 30분 전] $title',
          '곧 \'$title\' 일정이 시작됩니다. 맞춤 호흡으로 마음을 가다듬어보세요 🌿',
          tzReminderTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: id,
        );
      } catch (e) {
        debugPrint('[LOCAL_NOTIF_EXACT_FALLBACK] Exact alarm failed, falling back to inexact mode: $e');
        await _plugin.zonedSchedule(
          notificationId,
          '[일정 30분 전] $title',
          '곧 \'$title\' 일정이 시작됩니다. 맞춤 호흡으로 마음을 가다듬어보세요 🌿',
          tzReminderTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: id,
        );
      }

      debugPrint('[LOCAL_NOTIF_SCHEDULED] Notification ID: $notificationId scheduled for "$title" at $tzReminderTime');
    } catch (e) {
      debugPrint('[LOCAL_NOTIF_SCHEDULE_ERROR] $e');
    }
  }

  /// Displays an instant push notification for testing purposes (triggers after 3 seconds)
  Future<void> showInstantTestNotification({
    String title = 'BPACE 호흡 리추얼 테스트',
    String body = '로컬 푸시 알림이 정상적으로 동작하고 있습니다! 🌿',
  }) async {
    await initialize();
    try {
      const androidDetails = AndroidNotificationDetails(
        'bpace_ritual_reminders',
        'BPACE 호흡 리추얼 알림',
        channelDescription: '일정 30분 전 맞춤 호흡 안내 알림',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 3));

      await _plugin.zonedSchedule(
        99999,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[LOCAL_NOTIF_TEST] Instant notification scheduled in 3 seconds.');
    } catch (e) {
      debugPrint('[LOCAL_NOTIF_TEST_ERROR] $e');
    }
  }

  /// Cancels an existing scheduled notification for a given schedule ID
  Future<void> cancelReminder(String id) async {
    try {
      final notificationId = id.hashCode.abs() % 100000;
      await _plugin.cancel(notificationId);
      debugPrint('[LOCAL_NOTIF_CANCELLED] Notification ID: $notificationId cancelled.');
    } catch (e) {
      debugPrint('[LOCAL_NOTIF_CANCEL_ERROR] $e');
    }
  }

  /// Parses date + time string (e.g. "오전 9:00", "오후 2:30", "14:30") into a DateTime object
  DateTime? _parseScheduleDateTime(DateTime date, String timeStr) {
    try {
      int hour = 14;
      int minute = 30;

      final parts = timeStr.trim().split(' ');
      if (parts.length == 2) {
        final period = parts[0];
        final timeParts = parts[1].split(':');
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);

        if (period == '오후' && hour < 12) hour += 12;
        if (period == '오전' && hour == 12) hour = 0;
      } else if (parts.length == 1 && timeStr.contains(':')) {
        final timeParts = parts[0].split(':');
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
      }

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }
}
