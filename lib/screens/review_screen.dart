import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/review_item.dart';
import '../theme/app_theme.dart';
import 'add_review_screen.dart' show kUnderstood, kSoSo, kNotYet;

class ReviewScreen extends StatelessWidget {
  final ReviewItem review;
  const ReviewScreen({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.reviewScreenTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // カード：内容表示
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SubjectBadge(subject: review.subject),
                        const SizedBox(width: 8),
                        UnderstandingBadge(understanding: review.understanding),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(icon: Icons.menu_book_rounded, label: l.materialInfoLabel, value: review.material),
                    const Divider(height: 24),
                    _InfoRow(icon: Icons.crop_free_rounded, label: l.unitInfoLabel, value: review.unit),
                    if (review.memo.isNotEmpty) ...[
                      const Divider(height: 24),
                      _InfoRow(icon: Icons.sticky_note_2_outlined, label: l.memoInfoLabel, value: review.memo),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 復習回数チップ
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDim,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.replay, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        l.reviewCountLabel(review.reviewCount),
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // 理解度ラベル
              Center(
                child: Text(l.todayUnderstandingQuestion, style: AppTextStyles.heading2),
              ),
              const SizedBox(height: 20),

              // 結果ボタン
              Column(
                children: [
                  _ResultButton(
                    label: l.understoodLabel,
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                    bgColor: AppColors.successDim,
                    onPressed: () => Navigator.pop(context, kUnderstood),
                  ),
                  const SizedBox(height: 10),
                  _ResultButton(
                    label: l.soSoLabel,
                    icon: Icons.help_outline,
                    color: AppColors.warning,
                    bgColor: AppColors.warningDim,
                    onPressed: () => Navigator.pop(context, kSoSo),
                  ),
                  const SizedBox(height: 10),
                  _ResultButton(
                    label: l.notYetLabel,
                    icon: Icons.cancel_outlined,
                    color: AppColors.danger,
                    bgColor: AppColors.dangerDim,
                    onPressed: () => Navigator.pop(context, kNotYet),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── サブウィジェット ────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(value, style: AppTextStyles.body)),
      ],
    );
  }
}

class _ResultButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onPressed;

  const _ResultButton({
    required this.label, required this.icon,
    required this.color, required this.bgColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
