import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 通知設定
  bool _notificationEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 21, minute: 0);

  // テーマ設定
  AppThemeMode _themeMode = AppThemeMode.system;
  int _darkStartHour = 18;
  int _darkEndHour   = 6;

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
      _notificationTime = TimeOfDay(
        hour:   settings['hour'] as int,
        minute: settings['minute'] as int,
      );
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
      await NotificationService.scheduleDailyNotification(
        hour: _notificationTime.hour,
        minute: _notificationTime.minute,
      );
    } else {
      await NotificationService.cancelNotification();
    }
    await NotificationService.saveSettings(
      enabled: value,
      hour:    _notificationTime.hour,
      minute:  _notificationTime.minute,
    );
    if (mounted) {
      _showSnackbar(value ? l.notificationEnabledMsg : l.notificationDisabledMsg);
    }
  }

  Future<void> _onPickNotificationTime() async {
    final l = AppLocalizations.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null) {
      setState(() => _notificationTime = picked);
      if (_notificationEnabled) {
        await NotificationService.scheduleDailyNotification(
          hour: picked.hour, minute: picked.minute,
        );
      }
      await NotificationService.saveSettings(
        enabled: _notificationEnabled,
        hour:    picked.hour,
        minute:  picked.minute,
      );
      if (mounted) {
        _showSnackbar(l.notificationTimeSetMsg(_fmt(picked.hour), _fmt(picked.minute)));
      }
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
                  themeMode: _themeMode,
                  darkStartHour: _darkStartHour,
                  darkEndHour: _darkEndHour,
                  onThemeModeChanged: _onThemeModeChanged,
                  onPickDarkStart: _onPickDarkStart,
                  onPickDarkEnd: _onPickDarkEnd,
                  fmt: _fmt,
                ),

                const Divider(height: 32),

                // ── 言語設定 ─────────────────────────────
                _SectionHeader(title: l.languageSection),
                _LanguageExpansionTile(),

                const Divider(height: 32),

                // ── 通知設定 ─────────────────────────────
                _SectionHeader(title: l.notificationsSection),

                SwitchListTile(
                  title: Text(l.dailyReminderTitle),
                  subtitle: Text(l.dailyReminderSubtitle),
                  value: _notificationEnabled,
                  activeColor: AppColors.primary,
                  onChanged: _onToggleNotification,
                ),
                ListTile(
                  title: Text(l.notificationTimeLabel),
                  subtitle: Text(
                    '${_fmt(_notificationTime.hour)}:${_fmt(_notificationTime.minute)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.access_time),
                  enabled: _notificationEnabled,
                  onTap: _notificationEnabled ? _onPickNotificationTime : null,
                ),

                const Divider(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Text(
                    l.notificationNote,
                    style: AppTextStyles.caption,
                  ),
                ),
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

// ── 言語選択：折りたたみパネル ──────────────────────────

class _LanguageExpansionTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = LocaleService.current;

    final String currentLabel = current.languageCode == 'en'
        ? l.languageEnglish
        : l.languageJapanese;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.zero,
        leading: const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
        title: Text(l.languageSection, style: const TextStyle(fontSize: 15)),
        subtitle: Text(currentLabel, style: AppTextStyles.caption),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          _langOption(context, 'ja', l.languageJapanese, '日本語', current),
          _langOption(context, 'en', l.languageEnglish, 'English', current),
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
      value: code,
      groupValue: current.languageCode,
      onChanged: (val) {
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
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (label != nativeName) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

/// テーマ設定：タップで開閉する折りたたみパネル
class _ThemeExpansionTile extends StatelessWidget {
  final AppThemeMode themeMode;
  final int darkStartHour;
  final int darkEndHour;
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

    String currentLabel;
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
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.zero,
        leading: Icon(currentIcon, color: AppColors.primary, size: 22),
        title: Text(l.themeSection, style: const TextStyle(fontSize: 15)),
        subtitle: Text(currentLabel, style: AppTextStyles.caption),
        iconColor: AppColors.textSecondary,
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
                  color: AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                    _timePicker(Icons.dark_mode,  l.darkStartLabel,  fmt(darkStartHour), onPickDarkStart),
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
      value: value,
      groupValue: themeMode,
      onChanged: onThemeModeChanged,
      activeColor: AppColors.primary,
      dense: true,
      title: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(
            fontSize: 14,
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
              color: AppColors.surface,
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
