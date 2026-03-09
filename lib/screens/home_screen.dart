import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/review_item.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/material_review_settings.dart';
import '../services/srs_service.dart';
import '../theme/app_theme.dart';
import 'add_review_screen.dart';
import 'review_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'trash_screen.dart';

enum _SortOrder { deadline, subject, newest }
enum _UrgencyLevel { overdue, today, future }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<ReviewItem> _allReviews = [];
  int _streak = 0;
  bool _isLoading = true;

  String _searchQuery = '';
  String? _selectedSubject;
  String? _selectedMaterial;
  bool _showAll = false;
  _SortOrder _sortOrder = _SortOrder.deadline;

  // 複数選択モード
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  final Map<String, int> _subjectColorMap = {};
  Map<String, MaterialReviewSettings> _materialSettingsMap = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final reviews = await _firestoreService.getReviewItems();
    final streak  = await _firestoreService.getStreak();
    final matList = await _firestoreService.getMaterialSettings();
    int idx = 0;
    for (final item in reviews) {
      if (!_subjectColorMap.containsKey(item.subject)) {
        _subjectColorMap[item.subject] = idx++;
      }
    }
    setState(() {
      _allReviews          = reviews;
      _streak              = streak;
      _materialSettingsMap = {for (final s in matList) s.materialName: s};
      _isLoading           = false;
    });
    _updateNotificationWithTodayCount();
  }

  Future<void> _updateNotificationWithTodayCount() async {
    final settings = await NotificationService.loadSettings();
    if (settings['enabled'] == true) {
      final times = settings['times'] as List<TimeOfDay>;
      if (times.isEmpty) return;
      final count = _todayReviews.length;
      final body  = count > 0
          ? '今日の復習が $count 件あります。さっそく確認しよう！'
          : null;
      await NotificationService.scheduleAllNotifications(times, body: body);
    }
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}';

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  List<ReviewItem> get _todayReviews {
    return _allReviews.where((item) {
      final d = DateTime(item.nextReviewAt.year, item.nextReviewAt.month, item.nextReviewAt.day);
      return !d.isAfter(_today);
    }).toList();
  }

  int get _completedTodayCount {
    return _allReviews.where((item) {
      final last = DateTime(item.lastReviewedAt.year, item.lastReviewedAt.month, item.lastReviewedAt.day);
      return last == _today && item.reviewCount > 0;
    }).length;
  }

  int get _totalTodayCount => _todayReviews.length + _completedTodayCount;

  List<ReviewItem> get _filteredList {
    List<ReviewItem> base = _showAll ? List.from(_allReviews) : _todayReviews;
    if (_selectedSubject != null) {
      base = base.where((item) => item.subject == _selectedSubject).toList();
    }
    if (_selectedMaterial != null) {
      base = base.where((item) => item.material == _selectedMaterial).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      base = base.where((item) =>
        item.subject.toLowerCase().contains(q) ||
        item.material.toLowerCase().contains(q) ||
        item.unit.toLowerCase().contains(q) ||
        item.memo.toLowerCase().contains(q)
      ).toList();
    }
    switch (_sortOrder) {
      case _SortOrder.deadline:
        base.sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
        break;
      case _SortOrder.subject:
        base.sort((a, b) => a.subject.compareTo(b.subject));
        break;
      case _SortOrder.newest:
        base.sort((a, b) => b.lastReviewedAt.compareTo(a.lastReviewedAt));
        break;
    }
    return base;
  }

  List<String> get _subjects {
    final seen = <String>{};
    return _allReviews.map((e) => e.subject).where((s) => seen.add(s)).toList();
  }

  List<String> get _materials {
    final seen = <String>{};
    return _allReviews
        .map((e) => e.material)
        .where((m) => m.isNotEmpty && seen.add(m))
        .toList();
  }

  Future<void> _goToAddScreen() async {
    final result = await Navigator.push<ReviewItem>(
      context,
      MaterialPageRoute(builder: (_) => const AddReviewScreen()),
    );
    if (result != null) {
      await _firestoreService.addReviewItem(result);
      await _loadAll();
    }
  }

  Future<void> _goToReviewScreen(ReviewItem review) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ReviewScreen(review: review)),
    );
    if (result != null && mounted) {
      final matSettings = _materialSettingsMap[review.material];
      final SrsResult srs;
      if (matSettings != null && matSettings.enabled) {
        srs = SrsService.calculateWithSettings(
          result:              result,
          currentIntervalDays: review.currentIntervalDays,
          easeFactor:          review.easeFactor,
          reviewCount:         review.reviewCount,
          settings:            matSettings,
        );
      } else {
        srs = SrsService.calculate(
          result:              result,
          currentIntervalDays: review.currentIntervalDays,
          easeFactor:          review.easeFactor,
        );
      }
      final updated = review.copyWith(
        reviewCount:         review.reviewCount + 1,
        lastReviewedAt:      DateTime.now(),
        nextReviewAt:        srs.nextReviewAt,
        currentIntervalDays: srs.currentIntervalDays,
        easeFactor:          srs.easeFactor,
      );
      await _firestoreService.updateReviewItem(updated);
      await _firestoreService.recordStudyLog();
      await _loadAll();
      if (mounted) _showResultSnackbar(result);
    }
  }

  // ── 複数選択モード ──────────────────────────────────────

  void _enterSelectionMode(ReviewItem item) {
    setState(() {
      _isSelectionMode = true;
      if (item.docId != null) _selectedIds.add(item.docId!);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(ReviewItem item) {
    if (item.docId == null) return;
    setState(() {
      if (_selectedIds.contains(item.docId)) {
        _selectedIds.remove(item.docId);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(item.docId!);
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (final item in _filteredList) {
        if (item.docId != null) _selectedIds.add(item.docId!);
      }
    });
  }

  Future<void> _moveSelectedToTrash() async {
    final targets = _allReviews
        .where((item) => _selectedIds.contains(item.docId))
        .toList();
    for (final item in targets) {
      await _firestoreService.softDeleteReviewItem(item);
    }
    final count = targets.length;
    _exitSelectionMode();
    await _loadAll();
    if (mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.delete_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(l.movedToTrash(count)),
        ]),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  void _showResultSnackbar(String result) {
    final l = AppLocalizations.of(context);
    Color color;
    IconData icon;
    String label;
    switch (result) {
      case 'できた':
        color = AppColors.success; icon = Icons.check_circle; label = l.understoodLabel; break;
      case '微妙':
        color = AppColors.warning; icon = Icons.help; label = l.soSoLabel; break;
      default:
        color = AppColors.danger; icon = Icons.cancel; label = l.notYetLabel;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text('${l.reviewScreenTitle}：$label'),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  String _sortLabel(_SortOrder order, AppLocalizations l) {
    switch (order) {
      case _SortOrder.deadline: return l.sortByDeadline;
      case _SortOrder.subject:  return l.sortBySubject;
      case _SortOrder.newest:   return l.sortByNewest;
    }
  }

  PopupMenuItem<_SortOrder> _sortMenuItem(_SortOrder value, String label, IconData icon) {
    final isSelected = _sortOrder == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
            color: isSelected ? AppColors.primary : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          )),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, size: 14, color: AppColors.primary),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l = AppLocalizations.of(context);
    final filtered = _filteredList;
    final hasFilter = _searchQuery.isNotEmpty || _selectedSubject != null || _selectedMaterial != null;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              title: Text(l.selectedCount(_selectedIds.length)),
              actions: [
                TextButton(
                  onPressed: _selectAll,
                  child: Text(l.selectAllAction),
                ),
              ],
            )
          : AppBar(
        title: const _AppBarTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: l.statisticsTooltip,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: l.settingsTooltip,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'refresh') await _loadAll();
              if (value == 'trash') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
              }
              if (value == 'logout') await _authService.signOut();
            },
            itemBuilder: (ctx) {
              final lm = AppLocalizations.of(ctx);
              return [
                PopupMenuItem(value: 'refresh', child: Row(children: [const Icon(Icons.refresh), const SizedBox(width: 8), Text(lm.menuRefresh)])),
                PopupMenuItem(value: 'trash',   child: Row(children: [const Icon(Icons.delete_outline_rounded), const SizedBox(width: 8), Text(lm.menuTrash)])),
                PopupMenuItem(value: 'logout',  child: Row(children: [const Icon(Icons.logout), const SizedBox(width: 8), Text(lm.menuLogout)])),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _TodaySummaryCard(
                    streak: _streak,
                    completed: _completedTodayCount,
                    total: _totalTodayCount,
                  ),
                  const SizedBox(height: 20),

                  // 検索バー
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: l.searchHint,
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 今日 / 全件 トグル
                  Row(
                    children: [
                      _ToggleChip(
                        label: l.filterTodayLabel, icon: Icons.today_rounded,
                        selected: !_showAll,
                        onTap: () => setState(() => _showAll = false),
                      ),
                      const SizedBox(width: 8),
                      _ToggleChip(
                        label: l.filterAllLabel, icon: Icons.list_rounded,
                        selected: _showAll,
                        onTap: () => setState(() => _showAll = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 科目フィルターチップ
                  if (_subjects.isNotEmpty) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _SubjectChip(
                            label: l.allSubjectsChip, selected: _selectedSubject == null,
                            colorIndex: -1,
                            onTap: () => setState(() => _selectedSubject = null),
                          ),
                          ..._subjects.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _SubjectChip(
                              label: e.value,
                              selected: _selectedSubject == e.value,
                              colorIndex: _subjectColorMap[e.value] ?? e.key,
                              onTap: () => setState(() =>
                                _selectedSubject = _selectedSubject == e.value ? null : e.value,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // 教材フィルターチップ
                  if (_materials.isNotEmpty) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _MaterialChip(
                            label: l.materialAllChip,
                            selected: _selectedMaterial == null,
                            onTap: () => setState(() => _selectedMaterial = null),
                          ),
                          ..._materials.map((m) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _MaterialChip(
                              label: m,
                              selected: _selectedMaterial == m,
                              onTap: () => setState(() =>
                                _selectedMaterial = _selectedMaterial == m ? null : m,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (_subjects.isNotEmpty || _materials.isNotEmpty)
                    const SizedBox(height: 6),

                  // リストヘッダー
                  Row(
                    children: [
                      SectionTitle(title: _showAll ? l.sectionAllItems : l.sectionTodayReviews),
                      const Spacer(),
                      PopupMenuButton<_SortOrder>(
                        padding: EdgeInsets.zero,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sort_rounded, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                _sortLabel(_sortOrder, l),
                                style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onSelected: (order) => setState(() => _sortOrder = order),
                        itemBuilder: (ctx) {
                          final ls = AppLocalizations.of(ctx);
                          return [
                            _sortMenuItem(_SortOrder.deadline, ls.sortByDeadline, Icons.access_time_rounded),
                            _sortMenuItem(_SortOrder.subject,  ls.sortBySubject,  Icons.label_outline_rounded),
                            _sortMenuItem(_SortOrder.newest,   ls.sortByNewest,   Icons.fiber_new_rounded),
                          ];
                        },
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDim,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5),
                        ),
                        child: Text(
                          l.nItemsCount(filtered.length),
                          style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),

            // 復習リスト
            filtered.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: SingleChildScrollView(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: hasFilter ? AppColors.primaryDim : AppColors.successDim,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  hasFilter ? Icons.search_off_rounded : Icons.check_rounded,
                                  size: 32,
                                  color: hasFilter ? AppColors.primary : AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                hasFilter
                                    ? l.noFilterResults
                                    : _showAll ? l.noItemsYet : l.allDoneToday,
                                style: AppTextStyles.heading2,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasFilter
                                    ? l.noFilterResultsHint
                                    : _showAll ? l.noItemsYetHint : l.allDoneTodayHint,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final colorIdx = _subjectColorMap[item.subject] ?? 0;
                        final isSelected = _selectedIds.contains(item.docId);
                        return _ReviewCard(
                          item: item,
                          colorIndex: colorIdx,
                          formatDate: _formatDate,
                          isSelectionMode: _isSelectionMode,
                          isSelected: isSelected,
                          onTap: _isSelectionMode
                              ? () => _toggleSelection(item)
                              : () => _goToReviewScreen(item),
                          onLongPress: _isSelectionMode
                              ? null
                              : () => _enterSelectionMode(item),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _goToAddScreen,
              icon: const Icon(Icons.add, size: 20),
              label: Text(l.registerFab, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
      bottomNavigationBar: _isSelectionMode
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: _selectedIds.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedIds.isEmpty ? l.longPressToSelect : l.selectedCount(_selectedIds.length),
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedIds.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _selectedIds.isEmpty ? null : _moveSelectedToTrash,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(l.moveToTrashButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.dangerDim,
                        disabledForegroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

// ── AppBar タイトル ─────────────────────────────────────

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7, height: 7,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        const Text('Review'),
      ],
    );
  }
}

// ── サブウィジェット ────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2,
              color: selected ? Colors.white : AppColors.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final int colorIndex;
  final VoidCallback onTap;
  const _SubjectChip({required this.label, required this.selected, required this.colorIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = colorIndex < 0
        ? AppColors.primary
        : AppColors.subjectColors[colorIndex % AppColors.subjectColors.length];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : color.withOpacity(0.3), width: 0.5),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2,
          color: selected ? Colors.white : color,
        )),
      ),
    );
  }
}

class _MaterialChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MaterialChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.overlay : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.textSecondary : AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book_outlined, size: 12,
              color: selected ? AppColors.textPrimary : AppColors.textHint),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  final int streak;
  final int completed;
  final int total;
  const _TodaySummaryCard({
    required this.streak,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ratio = total == 0 ? 1.0 : completed / total;
    final isAllDone = total > 0 && completed >= total;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = isAllDone ? AppColors.success : AppColors.primary;
    final cardColor = isAllDone
        ? (isDark ? AppColors.successDim : AppLightColors.successDim)
        : (isDark ? AppColors.primaryDim : AppLightColors.primaryDim);

    return AppCard(
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 今日のカウント＆ラベル
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAllDone ? Icons.done_all_rounded : Icons.today_rounded,
                          size: 14, color: accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAllDone ? l.todayProgressDone : l.todayProgressLabel,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: accent, letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    total == 0
                        ? Text(
                            l.noSchedule,
                            style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700,
                              color: accent, letterSpacing: -0.5,
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$completed',
                                style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800,
                                  color: accent, letterSpacing: -1.5,
                                ),
                              ),
                              Text(
                                ' / $total',
                                style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600,
                                  color: accent.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              // Streak バッジ（streak > 0 のときのみ）
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3), width: 0.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(height: 2),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: AppColors.primary, letterSpacing: -1,
                        ),
                      ),
                      Text(
                        l.streakStudying,
                        style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w500,
                          color: AppColors.textOnDim,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: AppColors.surfaceHigh,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewItem item;
  final int colorIndex;
  final String Function(DateTime) formatDate;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ReviewCard({
    required this.item, required this.colorIndex,
    required this.formatDate,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
  });

  _UrgencyLevel _urgency() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(item.nextReviewAt.year, item.nextReviewAt.month, item.nextReviewAt.day);
    if (d.isBefore(today)) return _UrgencyLevel.overdue;
    if (d == today)         return _UrgencyLevel.today;
    return _UrgencyLevel.future;
  }

  Color _dateColor(_UrgencyLevel u) {
    switch (u) {
      case _UrgencyLevel.overdue: return AppColors.danger;
      case _UrgencyLevel.today:   return AppColors.primary;
      case _UrgencyLevel.future:  return AppColors.textSecondary;
    }
  }

  Color _dateBg(_UrgencyLevel u) {
    switch (u) {
      case _UrgencyLevel.overdue: return AppColors.dangerDim;
      case _UrgencyLevel.today:   return AppColors.primaryDim;
      case _UrgencyLevel.future:  return Colors.transparent;
    }
  }

  String _dateLabel(_UrgencyLevel u, AppLocalizations l) {
    switch (u) {
      case _UrgencyLevel.overdue: return l.overdueLabel;
      case _UrgencyLevel.today:   return l.todayLabel;
      case _UrgencyLevel.future:  return formatDate(item.nextReviewAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accentColor = AppColors.subjectColors[colorIndex % AppColors.subjectColors.length];
    final urgency = _urgency();
    return GestureDetector(
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary, width: 2),
              )
            : null,
        child: AppCard(
          onTap: onTap,
          color: isSelected ? AppColors.primaryMid : null,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isSelected ? 8 : 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 左アクセントバー（選択時は太く＋primary色）
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: isSelected ? 6 : 4,
                    color: isSelected ? AppColors.primary : accentColor,
                  ),
                  const SizedBox(width: 14),
                  // メインコンテンツ
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SubjectBadge(subject: item.subject, colorIndex: colorIndex),
                              const SizedBox(width: 8),
                              UnderstandingBadge(understanding: item.understanding),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(item.unit, style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: -0.2,
                          )),
                          if (item.material.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(item.material, style: AppTextStyles.caption),
                          ],
                          if (item.memo.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.notes_rounded, size: 11, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.memo,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // 右側：選択モードはチェックボックス、通常は日付＋回数＋矢印
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: isSelectionMode
                          ? [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  key: ValueKey(isSelected),
                                  size: 24,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ]
                          : [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _dateBg(urgency),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  _dateLabel(urgency, l),
                                  style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: _dateColor(urgency),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(l.reviewNthTime(item.reviewCount),
                                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                              const SizedBox(height: 6),
                              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
