import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewItem {
  final String? docId;
  final String  subject;
  final String  material;
  final String  unit;
  final String  memo;
  final String  understanding;
  final int     reviewCount;
  final DateTime lastReviewedAt;
  final DateTime nextReviewAt;
  final DateTime? deletedAt; // null = アクティブ、non-null = ゴミ箱

  // ── SRS フィールド ──────────────────────────────────────
  /// 現在の復習インターバル（日数）。初期値 1.0。
  final double currentIntervalDays;

  /// 難易度係数。大きいほど次回スパンが長くなる。初期値 2.0、範囲 1.3〜3.0。
  final double easeFactor;

  /// true のとき通常一覧・通知から除外する（"習得済み"アーカイブ）。
  final bool isArchived;

  const ReviewItem({
    this.docId,
    required this.subject,
    required this.material,
    required this.unit,
    required this.memo,
    required this.understanding,
    required this.reviewCount,
    required this.lastReviewedAt,
    required this.nextReviewAt,
    this.deletedAt,
    this.currentIntervalDays = 1.0,
    this.easeFactor          = 2.0,
    this.isArchived          = false,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'subject':              subject,
      'material':             material,
      'unit':                 unit,
      'memo':                 memo,
      'understanding':        understanding,
      'reviewCount':          reviewCount,
      'lastReviewedAt':       Timestamp.fromDate(lastReviewedAt),
      'nextReviewAt':         Timestamp.fromDate(nextReviewAt),
      'deletedAt':            deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      // SRS
      'currentIntervalDays':  currentIntervalDays,
      'easeFactor':           easeFactor,
      'isArchived':           isArchived,
    };
  }

  factory ReviewItem.fromMap(String docId, Map<String, dynamic> map) {
    return ReviewItem(
      docId:          docId,
      subject:        map['subject']       as String,
      material:       map['material']      as String,
      unit:           map['unit']          as String,
      memo:           map['memo']          as String,
      understanding:  map['understanding'] as String,
      reviewCount:    map['reviewCount']   as int,
      lastReviewedAt: (map['lastReviewedAt'] as Timestamp).toDate(),
      nextReviewAt:   (map['nextReviewAt']   as Timestamp).toDate(),
      deletedAt:      map['deletedAt'] != null
          ? (map['deletedAt'] as Timestamp).toDate()
          : null,
      // SRS: 旧データに null の場合はデフォルト値にフォールバック
      currentIntervalDays: (map['currentIntervalDays'] as num?)?.toDouble() ?? 1.0,
      easeFactor:          (map['easeFactor']          as num?)?.toDouble() ?? 2.0,
      isArchived:          (map['isArchived']           as bool?) ?? false,
    );
  }

  ReviewItem copyWith({
    String?   docId,
    String?   subject,
    String?   material,
    String?   unit,
    String?   memo,
    String?   understanding,
    int?      reviewCount,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    DateTime? deletedAt,
    bool      clearDeletedAt = false,
    // SRS
    double?   currentIntervalDays,
    double?   easeFactor,
    bool?     isArchived,
  }) {
    return ReviewItem(
      docId:               docId          ?? this.docId,
      subject:             subject        ?? this.subject,
      material:            material       ?? this.material,
      unit:                unit           ?? this.unit,
      memo:                memo           ?? this.memo,
      understanding:       understanding  ?? this.understanding,
      reviewCount:         reviewCount    ?? this.reviewCount,
      lastReviewedAt:      lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt:        nextReviewAt   ?? this.nextReviewAt,
      deletedAt:           clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      // SRS
      currentIntervalDays: currentIntervalDays ?? this.currentIntervalDays,
      easeFactor:          easeFactor          ?? this.easeFactor,
      isArchived:          isArchived          ?? this.isArchived,
    );
  }
}
