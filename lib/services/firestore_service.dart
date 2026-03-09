import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_item.dart';
import '../models/material_review_settings.dart';

class FirestoreService {
  // ── コレクション参照 ────────────────────────────────────

  CollectionReference get _reviewCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users').doc(uid).collection('review_items');
  }

  CollectionReference get _studyLogCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users').doc(uid).collection('study_logs');
  }

  CollectionReference get _materialSettingsCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users').doc(uid).collection('material_settings');
  }

  // ===============================
  // review_items 操作
  // ===============================

  Future<void> addReviewItem(ReviewItem item) async {
    await _reviewCollection.add(item.toMap());
  }

  /// アクティブな復習アイテムを取得（ゴミ箱・アーカイブ済み除外）
  Future<List<ReviewItem>> getReviewItems() async {
    final snapshot = await _reviewCollection.get();
    return snapshot.docs
        .map((doc) => ReviewItem.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .where((item) => !item.isDeleted && !item.isArchived)
        .toList();
  }

  Future<List<ReviewItem>> getTrashItems() async {
    final snapshot = await _reviewCollection.get();
    final items = snapshot.docs
        .map((doc) => ReviewItem.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .where((item) => item.isDeleted)
        .toList();
    items.sort((a, b) =>
        (b.deletedAt ?? DateTime.now()).compareTo(a.deletedAt ?? DateTime.now()));
    return items;
  }

  Future<void> updateReviewItem(ReviewItem item) async {
    if (item.docId == null) return;
    await _reviewCollection.doc(item.docId).update(item.toMap());
  }

  Future<void> softDeleteReviewItem(ReviewItem item) async {
    if (item.docId == null) return;
    await _reviewCollection.doc(item.docId).update({
      'deletedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> restoreReviewItem(ReviewItem item) async {
    if (item.docId == null) return;
    await _reviewCollection.doc(item.docId).update({'deletedAt': null});
  }

  Future<void> permanentlyDeleteReviewItem(ReviewItem item) async {
    if (item.docId == null) return;
    await _reviewCollection.doc(item.docId).delete();
  }

  Future<List<String>> getMaterialSuggestions() async {
    final snapshot = await _reviewCollection.get();
    final materials = snapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['material'] as String? ?? '').trim();
        })
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return materials;
  }

  // ===============================
  // material_settings 操作
  // ===============================

  /// 全教材設定を取得する
  Future<List<MaterialReviewSettings>> getMaterialSettings() async {
    final snapshot = await _materialSettingsCollection.get();
    return snapshot.docs
        .map((doc) => MaterialReviewSettings.fromMap(
              doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// 教材設定を保存（docId があれば更新、なければ追加）
  Future<void> saveMaterialSetting(MaterialReviewSettings settings) async {
    if (settings.docId != null) {
      await _materialSettingsCollection
          .doc(settings.docId)
          .update(settings.toMap());
    } else {
      await _materialSettingsCollection.add(settings.toMap());
    }
  }

  /// 教材設定を削除
  Future<void> deleteMaterialSetting(MaterialReviewSettings settings) async {
    if (settings.docId == null) return;
    await _materialSettingsCollection.doc(settings.docId).delete();
  }

  // ===============================
  // study_logs 操作（streak用）
  // ===============================

  String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> recordStudyLog() async {
    final today = _dateKey(DateTime.now());
    await _studyLogCollection.doc(today).set({'studied': true});
  }

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

  // ===============================
  // アカウント管理
  // ===============================

  /// users/{uid} に isDeactivated: true, deactivatedAt: serverTimestamp を書き込む。
  /// 認証・ログアウト処理はこのメソッドでは行わない。
  Future<void> deactivateAccount() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'isDeactivated': true,
        'deactivatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
