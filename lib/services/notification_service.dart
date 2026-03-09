import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // 複数時刻: ID = _baseId + index（0〜_maxSlots-1）
  static const int _baseNotificationId = 100;
  static const int _maxSlots           = 20;

  static const String _prefEnabled = 'notification_enabled';
  // "HH:MM,HH:MM,..." 形式で保存
  static const String _prefTimes   = 'notification_times';

  // ── 初期化（main.dart で一度だけ呼ぶ）────────────────────────
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
      iOS:     iosSettings,
    );

    await _plugin.initialize(initSettings);
  }

  // ── 通知権限をリクエスト（iOS / Android 13+）──────────────────
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

  // ── 全通知をキャンセル ───────────────────────────────────────
  static Future<void> cancelAllNotifications() async {
    for (int i = 0; i < _maxSlots; i++) {
      await _plugin.cancel(_baseNotificationId + i);
    }
  }

  // ── 複数時刻を一括スケジュール ──────────────────────────────
  static Future<void> scheduleAllNotifications(
    List<TimeOfDay> times, {
    String? title,
    String? body,
  }) async {
    await cancelAllNotifications();

    if (times.isEmpty) return;

    final resolvedTitle = title ?? '今日の復習をしましょう 📚';
    final resolvedBody  = body  ?? 'Review App を開いて今日の復習を確認しよう！';

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_review_channel',
        '毎日の復習リマインダー',
        channelDescription: '毎日の復習を促す通知です',
        importance: Importance.high,
        priority:   Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < times.length && i < _maxSlots; i++) {
      final t = times[i];
      var scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, t.hour, t.minute,
      );
      // 今日の指定時刻がすでに過ぎていたら翌日にする
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _baseNotificationId + i,
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
  }

  // ── 設定を保存（複数時刻リスト）────────────────────────────
  static Future<void> saveSettings({
    required bool           enabled,
    required List<TimeOfDay> times,
  }) async {
    final prefs   = await SharedPreferences.getInstance();
    final encoded = times
        .map((t) =>
            '${t.hour.toString().padLeft(2, '0')}:'
            '${t.minute.toString().padLeft(2, '0')}')
        .join(',');
    await prefs.setBool(  _prefEnabled, enabled);
    await prefs.setString(_prefTimes,   encoded);
  }

  // ── 設定を読み込む ────────────────────────────────────────
  static Future<Map<String, dynamic>> loadSettings() async {
    final prefs   = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefEnabled) ?? false;

    List<TimeOfDay> times;
    final timesStr = prefs.getString(_prefTimes);

    if (timesStr != null && timesStr.isNotEmpty) {
      // 新フォーマット: "HH:MM,HH:MM"
      times = timesStr
          .split(',')
          .where((s) => s.contains(':'))
          .map((s) {
            final parts = s.split(':');
            return TimeOfDay(
              hour:   int.tryParse(parts[0]) ?? 21,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          })
          .toList();
    } else {
      // 旧フォーマット互換（single hour/minute）
      final oldHour   = prefs.getInt('notification_hour');
      final oldMinute = prefs.getInt('notification_minute');
      times = [
        TimeOfDay(hour: oldHour ?? 21, minute: oldMinute ?? 0),
      ];
    }

    return {'enabled': enabled, 'times': times};
  }

  // ── 起動時に再スケジュール（main.dart から呼ぶ）──────────────
  static Future<void> rescheduleIfEnabled() async {
    final settings = await loadSettings();
    if (settings['enabled'] == true) {
      final times = settings['times'] as List<TimeOfDay>;
      await scheduleAllNotifications(times);
    }
  }
}
