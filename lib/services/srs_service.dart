import 'dart:math';
import '../models/material_review_settings.dart';

// 理解度の固定キー（add_review_screen.dart と同値）
const String _kUnderstood = 'できた';
const String _kSoSo       = '微妙';
// 上記以外はすべて 'できない' 扱い

/// SRS 計算結果
class SrsResult {
  final double   currentIntervalDays;
  final double   easeFactor;
  final DateTime nextReviewAt;

  const SrsResult({
    required this.currentIntervalDays,
    required this.easeFactor,
    required this.nextReviewAt,
  });
}

/// Spaced Repetition System（間隔反復）計算サービス
///
/// 依存なし・純粋 Dart。Firebase・Flutter 非依存のため単体テスト可能。
class SrsService {
  SrsService._(); // インスタンス化禁止

  // ── 定数 ────────────────────────────────────────────────
  static const double _easeMax          = 3.0;
  static const double _easeFloorSoSo    = 1.4;
  static const double _easeFloorNotYet  = 1.3;

  // ── デフォルト復習アルゴリズム ──────────────────────────

  /// 復習結果 [result] と現在の SRS 状態から次回スケジュールを計算する。
  static SrsResult calculate({
    required String result,
    required double currentIntervalDays,
    required double easeFactor,
  }) {
    final double newInterval;
    final double newEase;

    if (result == _kUnderstood) {
      newInterval = max(1.0, currentIntervalDays * easeFactor);
      newEase     = min(_easeMax, easeFactor + 0.15);
    } else if (result == _kSoSo) {
      newInterval = max(1.0, currentIntervalDays * 1.2);
      newEase     = max(_easeFloorSoSo, easeFactor - 0.05);
    } else {
      newInterval = 1.0;
      newEase     = max(_easeFloorNotYet, easeFactor - 0.2);
    }

    return _toResult(newInterval, newEase);
  }

  // ── 教材カスタム設定を使った復習アルゴリズム ─────────────

  /// [settings] が enabled なときだけ呼ぶ。
  /// [reviewCount] は更新前の回数（0 = 初回復習）。
  static SrsResult calculateWithSettings({
    required String                  result,
    required double                  currentIntervalDays,
    required double                  easeFactor,
    required int                     reviewCount,
    required MaterialReviewSettings  settings,
  }) {
    final double newInterval;
    final double newEase;

    if (result == _kUnderstood) {
      // 初回 = easyBaseDays、以後は currentInterval * growthMultiplier
      newInterval = reviewCount == 0
          ? settings.easyBaseDays
          : max(settings.easyBaseDays,
                currentIntervalDays * settings.growthMultiplier);
      newEase = min(_easeMax, easeFactor + 0.15);
    } else if (result == _kSoSo) {
      // mediumBaseDays をベースに、現在より短くならない程度で少し伸ばす
      newInterval = max(settings.mediumBaseDays, currentIntervalDays * 1.1);
      newEase     = max(_easeFloorSoSo, easeFactor - 0.05);
    } else {
      // できない: hardBaseDays にリセット
      newInterval = settings.hardBaseDays;
      newEase     = max(_easeFloorNotYet, easeFactor - 0.2);
    }

    return _toResult(newInterval, newEase);
  }

  // ── 内部ヘルパー ─────────────────────────────────────────

  static SrsResult _toResult(double newInterval, double newEase) {
    final days = newInterval.ceil().clamp(1, 3650);
    final now  = DateTime.now();
    return SrsResult(
      currentIntervalDays: newInterval,
      easeFactor:          newEase,
      nextReviewAt:        DateTime(now.year, now.month, now.day + days),
    );
  }
}
