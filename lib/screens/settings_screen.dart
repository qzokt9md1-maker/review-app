import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../services/notification_service.dart';
import 'material_settings_screen.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // 通知設定
  bool             _notificationEnabled = false;
  List<TimeOfDay>  _notificationTimes   = [];

  // テーマ設定
  AppThemeMode _themeMode    = AppThemeMode.system;
  int          _darkStartHour = 18;
  int          _darkEndHour   = 6;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationService.loadSettings();
    setState(() {
      _notificationEnabled = settings['enabled'] as bool;
      _notificationTimes   = settings['times']   as List<TimeOfDay>;
      _themeMode     = ThemeService.mode;
      _darkStartHour = ThemeService.darkStartHour;
      _darkEndHour   = ThemeService.darkEndHour;
      _isLoading = false;
    });
  }

  // ── 通知 ──────────────────────────────────────────────

  Future<void> _onToggleNotification(bool value) async {
    final l = AppLocalizations.of(context);
    setState(() => _notificationEnabled = value);
    if (value) {
      await NotificationService.requestPermission();
      if (_notificationTimes.isNotEmpty) {
        await NotificationService.scheduleAllNotifications(_notificationTimes);
      }
    } else {
      await NotificationService.cancelAllNotifications();
    }
    await NotificationService.saveSettings(
      enabled: value,
      times:   _notificationTimes,
    );
    if (mounted) {
      _showSnackbar(value ? l.notificationEnabledMsg : l.notificationDisabledMsg);
    }
  }

  Future<void> _onAddTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 21, minute: 0),
    );
    if (picked == null || !mounted) return;

    // 重複チェック
    final isDuplicate = _notificationTimes.any(
      (t) => t.hour == picked.hour && t.minute == picked.minute,
    );
    if (isDuplicate) {
      _showSnackbar('${_fmt(picked.hour)}:${_fmt(picked.minute)} はすでに登録されています');
      return;
    }

    // 時間順にソートして追加
    final updated = [..._notificationTimes, picked]
      ..sort((a, b) =>
          a.hour != b.hour ? a.hour - b.hour : a.minute - b.minute);

    setState(() => _notificationTimes = updated);

    if (_notificationEnabled) {
      await NotificationService.scheduleAllNotifications(updated);
    }
    await NotificationService.saveSettings(
      enabled: _notificationEnabled,
      times:   updated,
    );

    if (mounted) {
      _showSnackbar('${_fmt(picked.hour)}:${_fmt(picked.minute)} を追加しました');
    }
  }

  Future<void> _onRemoveTime(int index) async {
    final removed = _notificationTimes[index];
    final updated = [..._notificationTimes]..removeAt(index);

    setState(() => _notificationTimes = updated);

    if (_notificationEnabled) {
      if (updated.isEmpty) {
        await NotificationService.cancelAllNotifications();
      } else {
        await NotificationService.scheduleAllNotifications(updated);
      }
    }
    await NotificationService.saveSettings(
      enabled: _notificationEnabled,
      times:   updated,
    );

    if (mounted) {
      _showSnackbar('${_fmt(removed.hour)}:${_fmt(removed.minute)} を削除しました');
    }
  }

  // ── テーマ ─────────────────────────────────────────────

  Future<void> _onThemeModeChanged(AppThemeMode? mode) async {
    if (mode == null) return;
    setState(() => _themeMode = mode);
    await ThemeService.setMode(mode);
  }

  Future<void> _onPickDarkStart() async {
    final l = AppLocalizations.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _darkStartHour, minute: 0),
      helpText: l.darkModeStartHelpText,
    );
    if (picked != null) {
      setState(() => _darkStartHour = picked.hour);
      await ThemeService.setAutoTimes(
        darkStartHour: picked.hour,
        darkEndHour:   _darkEndHour,
      );
      if (mounted) {
        _showSnackbar(l.darkStartSetMsg(_fmt(picked.hour)));
      }
    }
  }

  Future<void> _onPickDarkEnd() async {
    final l = AppLocalizations.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _darkEndHour, minute: 0),
      helpText: l.lightModeReturnHelpText,
    );
    if (picked != null) {
      setState(() => _darkEndHour = picked.hour);
      await ThemeService.setAutoTimes(
        darkStartHour: _darkStartHour,
        darkEndHour:   picked.hour,
      );
      if (mounted) {
        _showSnackbar(l.lightReturnSetMsg(_fmt(picked.hour)));
      }
    }
  }

  // ── ユーティリティ ─────────────────────────────────────

  String _fmt(int n) => n.toString().padLeft(2, '0');

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── アカウント管理 ─────────────────────────────────────

  Future<void> _showDeactivateDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('アカウントを削除'),
        content: const Text(
          'アカウントを削除すると、このアプリは利用できなくなります。\n\n'
          'データはすぐには削除されず、後から復元できる可能性があります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text(
              '削除する',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _firestoreService.deactivateAccount();
      if (mounted) _showSnackbar('アカウントを削除しました');
    } catch (e) {
      if (mounted) _showSnackbar('エラーが発生しました。もう一度お試しください。');
    }
  }

  // ── ビルド ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [

                // ── テーマ設定（折りたたみ）──────────────
                _ThemeExpansionTile(
                  themeMode:           _themeMode,
                  darkStartHour:       _darkStartHour,
                  darkEndHour:         _darkEndHour,
                  onThemeModeChanged:  _onThemeModeChanged,
                  onPickDarkStart:     _onPickDarkStart,
                  onPickDarkEnd:       _onPickDarkEnd,
                  fmt:                 _fmt,
                ),

                const Divider(height: 32),

                // ── 言語設定 ─────────────────────────────
                _SectionHeader(title: l.languageSection),
                _LanguageExpansionTile(),

                const Divider(height: 32),

                // ── 教材設定 ─────────────────────────────
                _SectionHeader(title: '教材設定'),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined,
                      color: AppColors.primary, size: 22),
                  title: const Text('教材ごとの復習スパン'),
                  subtitle: const Text('教材別に復習間隔をカスタマイズ'),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MaterialSettingsScreen()),
                  ),
                ),

                const Divider(height: 32),

                // ── 通知設定 ─────────────────────────────
                _SectionHeader(title: l.notificationsSection),

                SwitchListTile(
                  title:       Text(l.dailyReminderTitle),
                  subtitle:    Text(l.dailyReminderSubtitle),
                  value:       _notificationEnabled,
                  activeColor: AppColors.primary,
                  onChanged:   _onToggleNotification,
                ),

                // 時刻リスト（ON/OFF 問わず常に表示）
                _NotificationTimeList(
                  times:    _notificationTimes,
                  enabled:  _notificationEnabled,
                  onAdd:    _onAddTime,
                  onRemove: _onRemoveTime,
                  fmt:      _fmt,
                ),

                const Divider(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Text(
                    l.notificationNote,
                    style: AppTextStyles.caption,
                  ),
                ),

                const Divider(height: 32),

                // ── アカウント管理 ─────────────────────────
                _SectionHeader(title: 'アカウント管理'),
                ListTile(
                  leading: const Icon(
                    Icons.block_rounded,
                    color: AppColors.danger,
                    size: 22,
                  ),
                  title: const Text(
                    'アカウントを削除',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('アカウントとデータを削除する'),
                  onTap: _showDeactivateDialog,
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

// ── サブウィジェット ────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SectionTitle(title: title),
    );
  }
}

// ── 通知時刻リスト ──────────────────────────────────────

class _NotificationTimeList extends StatelessWidget {
  final List<TimeOfDay> times;
  final bool            enabled;
  final VoidCallback    onAdd;
  final void Function(int) onRemove;
  final String Function(int) fmt;

  const _NotificationTimeList({
    required this.times,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primary : AppLightColors.primary;
    final dimColor     = isDark ? AppColors.primaryDim : AppLightColors.primaryDim;
    final textColor    = isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final hintColor    = isDark ? AppColors.textSecondary : AppLightColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── 登録済み時刻チップ ──────────────────────────
          if (times.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '通知時刻が登録されていません',
                style: TextStyle(fontSize: 13, color: hintColor),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing:    8,
                runSpacing: 8,
                children: times.asMap().entries.map((e) {
                  final idx = e.key;
                  final t   = e.value;
                  return _TimeChip(
                    label:       '${fmt(t.hour)}:${fmt(t.minute)}',
                    enabled:     enabled,
                    primaryColor: primaryColor,
                    dimColor:    dimColor,
                    textColor:   textColor,
                    hintColor:   hintColor,
                    onDelete:    () => onRemove(idx),
                  );
                }).toList(),
              ),
            ),

          // ── 時刻を追加ボタン ────────────────────────────
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon:  Icon(Icons.add_alarm_rounded, size: 16, color: primaryColor),
              label: Text(
                '時刻を追加',
                style: TextStyle(fontSize: 13, color: primaryColor),
              ),
              style: OutlinedButton.styleFrom(
                side:    BorderSide(color: primaryColor.withOpacity(0.5)),
                shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 時刻チップ ──────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  final String   label;
  final bool     enabled;
  final Color    primaryColor;
  final Color    dimColor;
  final Color    textColor;
  final Color    hintColor;
  final VoidCallback onDelete;

  const _TimeChip({
    required this.label,
    required this.enabled,
    required this.primaryColor,
    required this.dimColor,
    required this.textColor,
    required this.hintColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        dimColor,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(
          color: enabled
              ? primaryColor.withOpacity(0.5)
              : primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size:  14,
            color: enabled ? primaryColor : primaryColor.withOpacity(0.5),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize:   14,
              fontWeight: FontWeight.w600,
              color:      enabled ? primaryColor : primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap:     onDelete,
            behavior:  HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(Icons.close_rounded, size: 14, color: hintColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 言語選択：折りたたみパネル ──────────────────────────

class _LanguageExpansionTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l       = AppLocalizations.of(context);
    final current = LocaleService.current;

    final String currentLabel = current.languageCode == 'en'
        ? l.languageEnglish
        : l.languageJapanese;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding:     const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.zero,
        leading:  const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
        title:    Text(l.languageSection, style: const TextStyle(fontSize: 15)),
        subtitle: Text(currentLabel, style: AppTextStyles.caption),
        iconColor:          AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          _langOption(context, 'ja', l.languageJapanese, '日本語', current),
          _langOption(context, 'en', l.languageEnglish,  'English', current),
        ],
      ),
    );
  }

  Widget _langOption(
    BuildContext context,
    String code,
    String label,
    String nativeName,
    Locale current,
  ) {
    final isSelected = current.languageCode == code;
    return RadioListTile<String>(
      value:      code,
      groupValue: current.languageCode,
      onChanged:  (val) {
        if (val != null) LocaleService.changeLocale(Locale(val));
      },
      activeColor: AppColors.primary,
      dense: true,
      title: Row(
        children: [
          const SizedBox(width: 2),
          Text(
            nativeName,
            style: TextStyle(
              fontSize:   14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (label != nativeName) ...[
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}

/// テーマ設定：タップで開閉する折りたたみパネル
class _ThemeExpansionTile extends StatelessWidget {
  final AppThemeMode themeMode;
  final int          darkStartHour;
  final int          darkEndHour;
  final ValueChanged<AppThemeMode?> onThemeModeChanged;
  final VoidCallback onPickDarkStart;
  final VoidCallback onPickDarkEnd;
  final String Function(int) fmt;

  const _ThemeExpansionTile({
    required this.themeMode,
    required this.darkStartHour,
    required this.darkEndHour,
    required this.onThemeModeChanged,
    required this.onPickDarkStart,
    required this.onPickDarkEnd,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    String  currentLabel;
    IconData currentIcon;
    switch (themeMode) {
      case AppThemeMode.system:
        currentLabel = l.themeSystem;
        currentIcon  = Icons.brightness_auto;
        break;
      case AppThemeMode.dark:
        currentLabel = l.themeAlwaysDark;
        currentIcon  = Icons.dark_mode;
        break;
      case AppThemeMode.light:
        currentLabel = l.themeAlwaysLight;
        currentIcon  = Icons.light_mode;
        break;
      case AppThemeMode.timeBased:
        currentLabel = l.themeTimeBasedSubtitle(fmt(darkStartHour), fmt(darkEndHour));
        currentIcon  = Icons.schedule;
        break;
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding:     const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.zero,
        leading:  Icon(currentIcon, color: AppColors.primary, size: 22),
        title:    Text(l.themeSection, style: const TextStyle(fontSize: 15)),
        subtitle: Text(currentLabel, style: AppTextStyles.caption),
        iconColor:          AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          _option(context, Icons.brightness_auto, l.themeSystem,     l.themeSystemDesc,    AppThemeMode.system),
          _option(context, Icons.dark_mode,        l.themeAlwaysDark, l.themeDarkDesc,      AppThemeMode.dark),
          _option(context, Icons.light_mode,       l.themeAlwaysLight,l.themeLightDesc,     AppThemeMode.light),
          _option(context, Icons.schedule,         l.themeTimeBased,  l.themeTimeBasedDesc, AppThemeMode.timeBased),

          if (themeMode == AppThemeMode.timeBased)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(8),
                  border:       Border.all(color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                    _timePicker(Icons.dark_mode,  l.darkStartLabel,   fmt(darkStartHour), onPickDarkStart),
                    const SizedBox(height: 10),
                    _timePicker(Icons.light_mode, l.lightReturnLabel, fmt(darkEndHour),   onPickDarkEnd),
                    const SizedBox(height: 8),
                    Text(
                      l.darkModeHoursDesc(fmt(darkStartHour), fmt(darkEndHour)),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, IconData icon, String title, String subtitle, AppThemeMode value) {
    final isSelected = themeMode == value;
    return RadioListTile<AppThemeMode>(
      value:      value,
      groupValue: themeMode,
      onChanged:  onThemeModeChanged,
      activeColor: AppColors.primary,
      dense: true,
      title: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(
            fontSize:   14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          )),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 26),
        child: Text(subtitle, style: AppTextStyles.caption),
      ),
    );
  }

  Widget _timePicker(IconData icon, String label, String time, VoidCallback onTap) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:  AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Text('$time:00', style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14,
            )),
          ),
        ),
      ],
    );
  }
}
