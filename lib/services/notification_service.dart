import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyNotificationId = 1;
  static const String _prefNotificationEnabled = 'notification_enabled';
  static const String _prefNotificationHour = 'notification_hour';
  static const String _prefNotificationMinute = 'notification_minute';

  // 初期化（main.dart で一度だけ呼ぶ）
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
  }

  // 通知権限をリクエスト（iOS / Android 13+）
  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // 毎日指定時刻に通知をスケジュール（件数を渡すと通知文に反映される）
  static Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
    int? todayCount, // 今日の復習件数（省略時はデフォルトメッセージ）
    String? title,
    String? body,
  }) async {
    final resolvedTitle = title ?? '今日の復習をしましょう 📚';
    final resolvedBody = todayCount != null
        ? '今日の復習が $todayCount 件あります。さっそく確認しよう！'
        : (body ?? 'Review App を開いて今日の復習を確認しよう！');
    await _plugin.cancel(_dailyNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 今日の指定時刻がすでに過ぎていたら翌日にする
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_review_channel',
        '毎日の復習リマインダー',
        channelDescription: '毎日の復習を促す通知です',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _dailyNotificationId,
      resolvedTitle,
      resolvedBody,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 毎日同じ時刻
    );
  }

  // 通知をキャンセル
  static Future<void> cancelNotification() async {
    await _plugin.cancel(_dailyNotificationId);
  }

  // 設定を保存
  static Future<void> saveSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotificationEnabled, enabled);
    await prefs.setInt(_prefNotificationHour, hour);
    await prefs.setInt(_prefNotificationMinute, minute);
  }

  // 設定を読み込む
  static Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_prefNotificationEnabled) ?? false,
      'hour': prefs.getInt(_prefNotificationHour) ?? 21,
      'minute': prefs.getInt(_prefNotificationMinute) ?? 0,
    };
  }

  // 保存済み設定で通知を再スケジュール（アプリ起動時に呼ぶ）
  static Future<void> rescheduleIfEnabled() async {
    final settings = await loadSettings();
    if (settings['enabled'] == true) {
      await scheduleDailyNotification(
        hour: settings['hour'] as int,
        minute: settings['minute'] as int,
      );
    }
  }
}
