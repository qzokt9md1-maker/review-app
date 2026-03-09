import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/review_item.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<ReviewItem> _allReviews = [];
  int _streak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final reviews = await _firestoreService.getReviewItems();
    final streak  = await _firestoreService.getStreak();
    setState(() {
      _allReviews = reviews;
      _streak     = streak;
      _isLoading  = false;
    });
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int get _todayCount => _allReviews.where((item) {
    final d = DateTime(
      item.nextReviewAt.year,
      item.nextReviewAt.month,
      item.nextReviewAt.day,
    );
    return !d.isAfter(_today);
  }).length;

  int get _totalReviewCount =>
      _allReviews.fold(0, (sum, item) => sum + item.reviewCount);

  Map<String, int> get _subjectCounts {
    final map = <String, int>{};
    for (final item in _allReviews) {
      map[item.subject] = (map[item.subject] ?? 0) + 1;
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final counts = _subjectCounts;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.statsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                children: [

                  // ── ストリーク ──────────────────────────────
                  if (_streak > 0) ...[
                    _StreakCard(streak: _streak),
                    const SizedBox(height: 14),
                  ],

                  // ── サマリーカード ──────────────────────────
                  SectionTitle(title: l.summarySection),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.library_books_rounded,
                          label: l.totalItemsLabel,
                          value: '${_allReviews.length}',
                          unit: l.itemsUnit,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.today_rounded,
                          label: l.todayReviewsLabel,
                          value: '$_todayCount',
                          unit: l.itemsUnit,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _StatCard(
                    icon: Icons.replay_rounded,
                    label: l.totalReviewsLabel,
                    value: '$_totalReviewCount',
                    unit: l.timesUnit,
                    color: AppColors.success,
                    isWide: true,
                  ),

                  const SizedBox(height: 28),

                  // ── 科目別 円グラフ ──────────────────────────
                  SectionTitle(title: l.subjectSection),
                  const SizedBox(height: 12),

                  if (counts.isEmpty)
                    AppCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bar_chart_rounded,
                                size: 44,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                l.noDataYet,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    _SubjectBarCard(
                      subjectCounts: counts,
                      total: _allReviews.length,
                    ),
                ],
              ),
            ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// ストリークカード
// ────────────────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.primaryDim,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 26,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$streak',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context).streakDaysUnit,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Text(
                AppLocalizations.of(context).streakContinuing,
                style: const TextStyle(fontSize: 12, color: AppColors.textOnDim),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// サマリーカード
// ────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isWide;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: isWide
          // 横レイアウト（wide 版）
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.caption),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(unit, style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ],
            )
          // 縦レイアウト（narrow 版）
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                const SizedBox(height: 12),
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(unit, style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// 円グラフカード（タッチ対応ドーナツ + 凡例）
// ────────────────────────────────────────────────────────────
// 科目別バーカード（棒グラフのみ）
// ────────────────────────────────────────────────────────────
class _SubjectBarCard extends StatelessWidget {
  final Map<String, int> subjectCounts;
  final int total;

  const _SubjectBarCard({
    required this.subjectCounts,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final entries = subjectCounts.entries.toList();

    return AppCard(
      child: Column(
        children: [
          ...entries.asMap().entries.map((e) {
            final idx     = e.key;
            final subject = e.value.key;
            final count   = e.value.value;
            final ratio   = total > 0 ? count / total : 0.0;
            final color   = AppColors.subjectColors[idx % AppColors.subjectColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SubjectLegendRow(
                subject: subject,
                count:   count,
                ratio:   ratio,
                color:   color,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// 凡例行（科目名 + プログレスバー + 件数）
// ────────────────────────────────────────────────────────────
class _SubjectLegendRow extends StatelessWidget {
  final String subject;
  final int count;
  final double ratio;
  final Color color;
  final bool isHighlighted;

  const _SubjectLegendRow({
    required this.subject,
    required this.count,
    required this.ratio,
    required this.color,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).round();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isHighlighted ? 1.0 : 0.78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // カラードット
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width:  isHighlighted ? 12 : 9,
                height: isHighlighted ? 12 : 9,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              // 科目名
              Expanded(
                child: Text(
                  subject,
                  style: AppTextStyles.body.copyWith(
                    fontWeight:
                        isHighlighted ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // パーセント
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              // 件数
              SizedBox(
                width: 48,
                child: Text(
                  AppLocalizations.of(context).nItemsCount(count),
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // プログレスバー
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isHighlighted ? 7 : 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isHighlighted ? color : color.withOpacity(0.68),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
