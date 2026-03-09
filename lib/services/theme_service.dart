import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// テーマモードの種類
enum AppThemeMode {
  system,    // システム設定に従う
  dark,      // 常にダーク
  light,     // 常にライト
  timeBased, // 時間帯で自動切替
}

class ThemeService {
  // アプリ全体から監視できる ValueNotifier
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.system);

  // 現在の設定
  static AppThemeMode _mode = AppThemeMode.system;
  static int _darkStartHour = 18; // ダークモード開始（デフォルト18時）
  static int _darkEndHour   = 6;  // ライトモード復帰（デフォルト6時）

  // 時間帯モード用タイマー
  static Timer? _timer;

  // ── 外部から読むプロパティ ─────────────────────────────
  static AppThemeMode get mode => _mode;
  static int get darkStartHour => _darkStartHour;
  static int get darkEndHour   => _darkEndHour;

  // ── 初期化（main.dart で呼ぶ）────────────────────────
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('theme_mode') ?? 0;
    _mode          = AppThemeMode.values[modeIndex];
    _darkStartHour = prefs.getInt('theme_dark_start') ?? 18;
    _darkEndHour   = prefs.getInt('theme_dark_end')   ?? 6;

    _applyTheme();
    _startTimerIfNeeded();
  }

  // ── モード変更（設定画面から呼ぶ）───────────────────────
  static Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    _applyTheme();
    _startTimerIfNeeded();
  }

  // ── 時間帯設定変更 ─────────────────────────────────────
  static Future<void> setAutoTimes({
    required int darkStartHour,
    required int darkEndHour,
  }) async {
    _darkStartHour = darkStartHour;
    _darkEndHour   = darkEndHour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_dark_start', darkStartHour);
    await prefs.setInt('theme_dark_end',   darkEndHour);
    if (_mode == AppThemeMode.timeBased) _applyTheme();
  }

  // ── 現在時刻からテーマを決定して notifier を更新 ─────────
  static void _applyTheme() {
    switch (_mode) {
      case AppThemeMode.dark:
        themeNotifier.value = ThemeMode.dark;
        break;
      case AppThemeMode.light:
        themeNotifier.value = ThemeMode.light;
        break;
      case AppThemeMode.system:
        themeNotifier.value = ThemeMode.system;
        break;
      case AppThemeMode.timeBased:
        themeNotifier.value = _isDarkTime() ? ThemeMode.dark : ThemeMode.light;
        break;
    }
  }

  // 現在が「ダーク時間帯」かどうか判定
  static bool _isDarkTime() {
    final now = DateTime.now().hour;
    if (_darkStartHour <= _darkEndHour) {
      // 例：10〜18時がダーク（通常パターン）
      return now >= _darkStartHour && now < _darkEndHour;
    } else {
      // 例：18〜6時がダーク（日をまたぐパターン）
      return now >= _darkStartHour || now < _darkEndHour;
    }
  }

  // 時間帯モードのとき、毎分チェックするタイマーを起動
  static void _startTimerIfNeeded() {
    _timer?.cancel();
    if (_mode == AppThemeMode.timeBased) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) => _applyTheme());
    }
  }

  static void dispose() {
    _timer?.cancel();
    themeNotifier.dispose();
  }
}
