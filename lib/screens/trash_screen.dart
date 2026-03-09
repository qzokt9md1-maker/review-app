import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/review_item.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<ReviewItem> _trashItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _isLoading = true);
    final items = await _firestoreService.getTrashItems();
    setState(() {
      _trashItems = items;
      _isLoading = false;
    });
  }

  Future<void> _restore(ReviewItem item) async {
    await _firestoreService.restoreReviewItem(item);
    await _loadTrash();
    if (mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.restore, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(l.restoredMessage),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  Future<void> _permanentlyDelete(ReviewItem item) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.permanentDeleteTitle),
        content: Text(l.permanentDeleteConfirm(item.subject, item.unit)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.deleteAction, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _firestoreService.permanentlyDeleteReviewItem(item);
      await _loadTrash();
    }
  }

  Future<void> _emptyTrash() async {
    if (_trashItems.isEmpty) return;
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.emptyTrashTitle),
        content: Text(l.emptyTrashConfirm(_trashItems.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.deleteAllAction, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      for (final item in _trashItems) {
        await _firestoreService.permanentlyDeleteReviewItem(item);
      }
      await _loadTrash();
    }
  }

  String _deletedAgo(DateTime deletedAt) {
    final diff = DateTime.now().difference(deletedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前に削除';
    if (diff.inHours < 24) return '${diff.inHours}時間前に削除';
    return '${diff.inDays}日前に削除';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded, size: 18),
            const SizedBox(width: 8),
            const Text('ゴミ箱'),
          ],
        ),
        actions: [
          if (_trashItems.isNotEmpty)
            TextButton(
              onPressed: _emptyTrash,
              child: const Text(
                'すべて削除',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trashItems.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadTrash,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    itemCount: _trashItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _trashItems[index];
                      return _TrashCard(
                        item: item,
                        deletedAgo: item.deletedAt != null
                            ? _deletedAgo(item.deletedAt!)
                            : '',
                        onRestore: () => _restore(item),
                        onDelete: () => _permanentlyDelete(item),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surfaceHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 36,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          const Text('ゴミ箱は空です', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          const Text(
            '削除した記録はここに表示されます',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

// ── ゴミ箱カード ─────────────────────────────────────────

class _TrashCard extends StatelessWidget {
  final ReviewItem item;
  final String deletedAgo;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashCard({
    required this.item,
    required this.deletedAgo,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorIdx = item.subject.hashCode % AppColors.subjectColors.length;
    final accentColor = AppColors.subjectColors[colorIdx.abs() % AppColors.subjectColors.length];

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左アクセントバー（薄め）
              Container(
                width: 4,
                color: accentColor.withOpacity(0.5),
              ),
              const SizedBox(width: 14),
              // メインコンテンツ
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 削除日時バッジ
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            deletedAgo,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          SubjectBadge(
                            subject: item.subject,
                            colorIndex: colorIdx.abs(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.unit,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: -0.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.material.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.material,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // 右側アクション
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 復元ボタン
                    _ActionButton(
                      icon: Icons.restore_rounded,
                      label: '復元',
                      color: AppColors.primary,
                      onTap: onRestore,
                    ),
                    const SizedBox(height: 8),
                    // 完全削除ボタン
                    _ActionButton(
                      icon: Icons.delete_forever_rounded,
                      label: '削除',
                      color: AppColors.danger,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
