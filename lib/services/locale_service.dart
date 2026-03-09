import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const _kLocaleKey = 'app_locale';

  /// アプリ全体から監視できる ValueNotifier
  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale('ja'));

  // ── 初期化（main.dart で await する）──────────────────────
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved != null) {
      localeNotifier.value = Locale(saved);
    }
  }

  // ── 言語変更（設定画面から呼ぶ）──────────────────────────
  static Future<void> changeLocale(Locale locale) async {
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }

  // ── 現在のロケール ─────────────────────────────────────
  static Locale get current => localeNotifier.value;

  static void dispose() {
    localeNotifier.dispose();
  }
}
