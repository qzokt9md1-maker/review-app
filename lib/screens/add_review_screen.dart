import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/review_item.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

// 理解度の内部値（Firestore に保存する固定キー）
const String kUnderstood = 'できた';
const String kSoSo       = '微妙';
const String kNotYet     = 'できない';

class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({super.key});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _subjectController  = TextEditingController();
  final _materialController = TextEditingController();
  final _unitController     = TextEditingController();
  final _memoController     = TextEditingController();
  final _materialFocusNode  = FocusNode();
  final _firestoreService   = FirestoreService();

  String _understanding = kUnderstood;
  List<String> _materialSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  // 画面表示時に一度だけ候補を取得してキャッシュ
  Future<void> _loadSuggestions() async {
    final suggestions = await _firestoreService.getMaterialSuggestions();
    if (mounted) setState(() => _materialSuggestions = suggestions);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _materialController.dispose();
    _unitController.dispose();
    _memoController.dispose();
    _materialFocusNode.dispose();
    super.dispose();
  }

  DateTime _calcInitialNextReviewAt(String understanding) {
    final now = DateTime.now();
    return understanding == kUnderstood
        ? now.add(const Duration(days: 3))
        : now.add(const Duration(days: 1));
  }

  void _save() {
    final l = AppLocalizations.of(context);
    if (_subjectController.text.trim().isEmpty ||
        _unitController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.subjectUnitRequired),
          backgroundColor: AppColors.dangerDim,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final item = ReviewItem(
      subject:        _subjectController.text.trim(),
      material:       _materialController.text.trim(),  // RawAutocomplete が直接更新
      unit:           _unitController.text.trim(),
      memo:           _memoController.text.trim(),
      understanding:  _understanding,
      reviewCount:    0,
      lastReviewedAt: DateTime.now(),
      nextReviewAt:   _calcInitialNextReviewAt(_understanding),
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final l    = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.addReviewTitle),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              l.saveAction,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── 基本情報 ───────────────────────────────
            SectionTitle(title: l.basicInfoSection),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  // 科目
                  _LabeledField(
                    label: l.subjectLabel,
                    child: TextField(
                      controller: _subjectController,
                      decoration: InputDecoration(hintText: l.subjectHint),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 教材名（オートコンプリート付き）
                  _LabeledField(
                    label: l.materialLabel,
                    child: RawAutocomplete<String>(
                      textEditingController: _materialController,
                      focusNode: _materialFocusNode,
                      displayStringForOption: (option) => option,
                      // 部分一致で候補を絞り込む
                      optionsBuilder: (textEditingValue) {
                        final query = textEditingValue.text.trim().toLowerCase();
                        if (query.isEmpty || _materialSuggestions.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return _materialSuggestions.where(
                          (s) => s.toLowerCase().contains(query),
                        );
                      },
                      // テキストフィールド本体（既存スタイルを維持）
                      fieldViewBuilder: (ctx, controller, focusNode, onSubmit) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(hintText: l.materialHint),
                          textInputAction: TextInputAction.next,
                          onEditingComplete: onSubmit,
                        );
                      },
                      // 候補リストのドロップダウン
                      optionsViewBuilder: (ctx, onSelected, options) {
                        final isDark =
                            Theme.of(ctx).brightness == Brightness.dark;
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 8,
                            shadowColor: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                            color: isDark
                                ? AppColors.overlay
                                : AppLightColors.surface,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 220),
                                child: ListView(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  shrinkWrap: true,
                                  children: options.map((option) {
                                    return InkWell(
                                      onTap: () => onSelected(option),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 11),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.menu_book_outlined,
                                              size: 15,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                option,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isDark
                                                      ? AppColors.textPrimary
                                                      : AppLightColors
                                                          .textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 単元
                  _LabeledField(
                    label: l.unitLabel,
                    child: TextField(
                      controller: _unitController,
                      decoration: InputDecoration(hintText: l.unitHint),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── メモ ───────────────────────────────────
            SectionTitle(title: l.memoSection),
            const SizedBox(height: 12),
            AppCard(
              child: TextField(
                controller: _memoController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l.memoHint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── 理解度 ─────────────────────────────────
            SectionTitle(title: l.understandingSection),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _UnderstandingOption(
                    value: kUnderstood,
                    displayLabel: l.understoodLabel,
                    groupValue: _understanding,
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                    description: l.nextIn3Days,
                    onChanged: (v) => setState(() => _understanding = v!),
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _UnderstandingOption(
                    value: kSoSo,
                    displayLabel: l.soSoLabel,
                    groupValue: _understanding,
                    icon: Icons.help_outline,
                    color: AppColors.warning,
                    description: l.nextIn2Days,
                    onChanged: (v) => setState(() => _understanding = v!),
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _UnderstandingOption(
                    value: kNotYet,
                    displayLabel: l.notYetLabel,
                    groupValue: _understanding,
                    icon: Icons.cancel_outlined,
                    color: AppColors.danger,
                    description: l.nextTomorrow,
                    onChanged: (v) => setState(() => _understanding = v!),
                    showDivider: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ── 保存ボタン ─────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(l.saveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── サブウィジェット ────────────────────────────────────

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _UnderstandingOption extends StatelessWidget {
  final String value;        // 内部値（Firestore保存用）
  final String displayLabel; // 表示ラベル（翻訳済み）
  final String groupValue;
  final IconData icon;
  final Color color;
  final String description;
  final ValueChanged<String?> onChanged;
  final bool showDivider;

  const _UnderstandingOption({
    required this.value,
    required this.displayLabel,
    required this.groupValue,
    required this.icon,
    required this.color,
    required this.description,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: color,
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return color;
        return AppColors.textSecondary;
      }),
      title: Row(
        children: [
          Icon(icon,
              color: isSelected ? color : AppColors.textSecondary, size: 19),
          const SizedBox(width: 10),
          Text(
            displayLabel,
            style: TextStyle(
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.normal,
              color: isSelected ? color : AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 10),
          Text(description, style: AppTextStyles.caption),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
