import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_item.dart';

class FirestoreService {
  // ログイン中ユーザーの review_items コレクションへの参照
  CollectionReference get _reviewCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('review_items');
  }

  // ログイン中ユーザーの study_logs コレクションへの参照
  CollectionReference get _studyLogCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('study_logs');
  }

  // ===============================
  // review_items 操作
  // ===============================

  // 新しい復習アイテムを追加する
  Future<void> addReviewItem(ReviewItem item) async {
    await _reviewCollection.add(item.toMap());
  }

  // アクティブな復習アイテムを取得する（ゴミ箱のものは除外）
  Future<List<ReviewItem>> getReviewItems() async {
    final snapshot = await _reviewCollection.get();
    return snapshot.docs
        .map((doc) => ReviewItem.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .where((item) => !item.isDeleted)
        .toList();
  }

  // ゴミ箱内のアイテムを取得する
  Future<List<ReviewItem>> getTrashItems() async {
    final snapshot = await _reviewCollection.get();
    final items = snapshot.docs
        .map((doc) => ReviewItem.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .where((item) => item.isDeleted)
        .toList();
    // 削除日時の新しい順
    items.sort((a, b) =>
        (b.deletedAt ?? DateTime.now()).compareTo(a.deletedAt ?? DateTime.now()));
    return items;
  }

  // 復習アイテムを更新する（docId が必要）
  Future<void> updateReviewItem(ReviewItem item) async {
    if (item.docId == null) return;
    await _reviewCollection.doc(item.docId).update(item.toMap());
  }

  // ゴミ箱へ移動（ソフトデリート）
  Future<void> softDeleteReviewItem(ReviewItem item) async {
    if (item.docId == null) return;
    await _reviewCollection.doc(item.docId).update({
      'deletedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ゴミ箱から復元
  Future<void> restoreReviewItem(ReviewItem item) async {
    if (item.docId == null) return;
    await _reviewCollection.doc(item.docId).update({
      'deletedAt': null,
    });
  }

  // 完全に削除（Firestore からドキュメントごと削除）
  Future<void> permanentlyDeleteReviewItem(ReviewItem item) async {
    if (item.docId == null) return;
    await _reviewCollection.doc(item.docId).delete();
  }

  // ===============================
  // study_logs 操作（streak用）
  // ===============================

  // 日付を "yyyy-MM-dd" 形式の文字列に変換するヘルパー
  String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  // 今日の学習ログを記録する（何回呼んでも1日1件）
  Future<void> recordStudyLog() async {
    final today = _dateKey(DateTime.now());
    await _studyLogCollection.doc(today).set({'studied': true});
  }

  // streak（連続学習日数）を計算して返す
  Future<int> getStreak() async {
    final snapshot = await _studyLogCollection.get();
    final studiedDays = snapshot.docs.map((doc) => doc.id).toSet();

    int streak = 0;
    DateTime current = DateTime.now();

    while (true) {
      final key = _dateKey(current);
      if (studiedDays.contains(key)) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}
