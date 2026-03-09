import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewItem {
  final String? docId;
  final String subject;
  final String material;
  final String unit;
  final String memo;
  final String understanding;
  final int reviewCount;
  final DateTime lastReviewedAt;
  final DateTime nextReviewAt;
  final DateTime? deletedAt; // null = アクティブ、non-null = ゴミ箱

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
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'material': material,
      'unit': unit,
      'memo': memo,
      'understanding': understanding,
      'reviewCount': reviewCount,
      'lastReviewedAt': Timestamp.fromDate(lastReviewedAt),
      'nextReviewAt': Timestamp.fromDate(nextReviewAt),
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  factory ReviewItem.fromMap(String docId, Map<String, dynamic> map) {
    return ReviewItem(
      docId: docId,
      subject: map['subject'] as String,
      material: map['material'] as String,
      unit: map['unit'] as String,
      memo: map['memo'] as String,
      understanding: map['understanding'] as String,
      reviewCount: map['reviewCount'] as int,
      lastReviewedAt: (map['lastReviewedAt'] as Timestamp).toDate(),
      nextReviewAt: (map['nextReviewAt'] as Timestamp).toDate(),
      deletedAt: map['deletedAt'] != null
          ? (map['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  ReviewItem copyWith({
    String? docId,
    String? subject,
    String? material,
    String? unit,
    String? memo,
    String? understanding,
    int? reviewCount,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return ReviewItem(
      docId: docId ?? this.docId,
      subject: subject ?? this.subject,
      material: material ?? this.material,
      unit: unit ?? this.unit,
      memo: memo ?? this.memo,
      understanding: understanding ?? this.understanding,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
