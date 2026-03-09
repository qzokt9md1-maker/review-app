import 'package:flutter/material.dart';
import '../models/material_review_settings.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class MaterialSettingsScreen extends StatefulWidget {
  const MaterialSettingsScreen({super.key});

  @override
  State<MaterialSettingsScreen> createState() => _MaterialSettingsScreenState();
}

class _MaterialSettingsScreenState extends State<MaterialSettingsScreen> {
  final _firestoreService = FirestoreService();
  List<MaterialReviewSettings> _settings = [];
  List<String> _materialSuggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await _firestoreService.getMaterialSettings();
    final sugg = await _firestoreService.getMaterialSuggestions();
    setState(() {
      _settings            = list;
      _materialSuggestions = sugg;
      _isLoading           = false;
    });
  }

  Future<void> _showEditDialog({MaterialReviewSettings? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.materialName ?? '');
    final easyCtrl = TextEditingController(
        text: (existing?.easyBaseDays ?? 3.0).toStringAsFixed(1));
    final medCtrl = TextEditingController(
        text: (existing?.mediumBaseDays ?? 2.0).toStringAsFixed(1));
    final hardCtrl = TextEditingController(
        text: (existing?.hardBaseDays ?? 1.0).toStringAsFixed(1));
    final multCtrl = TextEditingController(
        text: (existing?.growthMultiplier ?? 2.0).toStringAsFixed(1));
    bool enabled = existing?.enabled ?? true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor:
                isDark ? AppColors.overlay : AppLightColors.surface,
            title: Text(existing == null ? '教材設定を追加' : '教材設定を編集',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 教材名（既存名のオートコンプリート）
                  if (existing == null && _materialSuggestions.isNotEmpty)
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: '教材名'),
                      value: _materialSuggestions.contains(nameCtrl.text)
                          ? nameCtrl.text
                          : null,
                      hint: const Text('選択または入力'),
                      items: _materialSuggestions
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) nameCtrl.text = v;
                      },
                    )
                  else
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: '教材名'),
                    ),
                  const SizedBox(height: 8),
                  _NumField(ctrl: easyCtrl,  label: 'できた　初期日数'),
                  _NumField(ctrl: medCtrl,   label: '微妙　　基準日数'),
                  _NumField(ctrl: hardCtrl,  label: 'できない リセット日数'),
                  _NumField(ctrl: multCtrl,  label: 'できた　伸び倍率'),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('この設定を有効にする',
                        style: TextStyle(fontSize: 14)),
                    value: enabled,
                    activeColor: isDark ? AppColors.primary : AppLightColors.primary,
                    onChanged: (v) => setDialogState(() => enabled = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final s = MaterialReviewSettings(
                    docId:            existing?.docId,
                    materialName:     name,
                    easyBaseDays:     double.tryParse(easyCtrl.text) ?? 3.0,
                    mediumBaseDays:   double.tryParse(medCtrl.text)  ?? 2.0,
                    hardBaseDays:     double.tryParse(hardCtrl.text) ?? 1.0,
                    growthMultiplier: double.tryParse(multCtrl.text) ?? 2.0,
                    enabled:          enabled,
                  );
                  await _firestoreService.saveMaterialSetting(s);
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _load();
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(MaterialReviewSettings s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('設定を削除'),
        content: Text('「${s.materialName}」の設定を削除しますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('削除',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      await _firestoreService.deleteMaterialSetting(s);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('教材設定')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEditDialog,
        icon:  const Icon(Icons.add, size: 20),
        label: const Text('追加', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings.isEmpty
              ? _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount:        _settings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final s = _settings[i];
                    return AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 教材名 + 有効バッジ
                                Row(children: [
                                  Expanded(
                                    child: Text(s.materialName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                  ),
                                  _EnabledChip(enabled: s.enabled, isDark: isDark),
                                ]),
                                const SizedBox(height: 8),
                                // スパン値
                                Wrap(
                                  spacing: 12, runSpacing: 6,
                                  children: [
                                    _SpanChip('できた',    s.easyBaseDays,   AppColors.success, AppColors.successDim),
                                    _SpanChip('微妙',      s.mediumBaseDays, AppColors.warning, AppColors.warningDim),
                                    _SpanChip('できない', s.hardBaseDays,   AppColors.danger,  AppColors.dangerDim),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(children: [
                                  const Icon(Icons.trending_up_rounded,
                                      size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text('伸び倍率 ×${s.growthMultiplier.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ]),
                              ],
                            ),
                          ),
                          // 操作ボタン
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18, color: AppColors.textSecondary),
                                onPressed: () => _showEditDialog(existing: s),
                                tooltip: '編集',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.danger),
                                onPressed: () => _delete(s),
                                tooltip: '削除',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ── サブウィジェット ────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
                color: AppColors.primaryDim, shape: BoxShape.circle),
            child: const Icon(Icons.menu_book_outlined,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          const Text('教材設定がありません',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('＋ 追加 で教材ごとの復習スパンを設定できます',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  const _NumField({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _EnabledChip extends StatelessWidget {
  final bool enabled;
  final bool isDark;
  const _EnabledChip({required this.enabled, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.success : AppColors.textSecondary;
    final bg    = enabled ? AppColors.successDim : AppColors.surfaceHigh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(enabled ? '有効' : '無効',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _SpanChip extends StatelessWidget {
  final String label;
  final double days;
  final Color  textColor;
  final Color  bgColor;
  const _SpanChip(this.label, this.days, this.textColor, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(5)),
      child: Text('$label: ${days.toStringAsFixed(1)}d',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}
