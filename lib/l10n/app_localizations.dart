import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ─────────────────────────────────────────────────────────────
// AppLocalizations — 抽象基底クラス
// ─────────────────────────────────────────────────────────────
abstract class AppLocalizations {
  const AppLocalizations();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ── Login ──────────────────────────────────────────────────
  String get loginTagline;
  String get emailLabel;
  String get passwordLabel;
  String get loginButton;
  String get orDivider;
  String get createAccountButton;
  String get loginErrorUserNotFound;
  String get loginErrorWrongPassword;
  String get loginErrorInvalidEmail;
  String get loginErrorTooManyRequests;
  String loginErrorDefault(String code);

  // ── Signup ─────────────────────────────────────────────────
  String get signupScreenTitle;
  String get signupHeading;
  String get signupTagline;
  String get passwordMinHint;
  String get signupButton;
  String get alreadyHaveAccount;
  String get signupErrorEmailInUse;
  String get signupErrorWeakPassword;
  String signupErrorDefault(String code);

  // ── Home ───────────────────────────────────────────────────
  String get statisticsTooltip;
  String get settingsTooltip;
  String get menuRefresh;
  String get menuTrash;
  String get menuLogout;
  String get searchHint;
  String get filterTodayLabel;
  String get filterAllLabel;
  String get allSubjectsChip;
  String get materialAllChip;
  String get sectionTodayReviews;
  String get sectionAllItems;
  String get sortByDeadline;
  String get sortBySubject;
  String get sortByNewest;
  String nItemsCount(int n);
  String selectedCount(int n);
  String get selectAllAction;
  String get longPressToSelect;
  String get moveToTrashButton;
  String movedToTrash(int n);
  String get noFilterResults;
  String get noFilterResultsHint;
  String get noItemsYet;
  String get noItemsYetHint;
  String get allDoneToday;
  String get allDoneTodayHint;
  String get streakStudying;
  String streakDays(int n);
  String get todayProgressDone;
  String get todayProgressLabel;
  String get noSchedule;
  String get overdueLabel;
  String get todayLabel;
  String reviewNthTime(int n);
  String get registerFab;

  // ── AddReview ──────────────────────────────────────────────
  String get addReviewTitle;
  String get saveAction;
  String get basicInfoSection;
  String get subjectLabel;
  String get subjectHint;
  String get materialLabel;
  String get materialHint;
  String get unitLabel;
  String get unitHint;
  String get memoSection;
  String get memoHint;
  String get understandingSection;
  String get saveButton;
  String get subjectUnitRequired;
  String get understoodLabel;
  String get soSoLabel;
  String get notYetLabel;
  String get nextIn3Days;
  String get nextIn2Days;
  String get nextTomorrow;

  // ── Review ─────────────────────────────────────────────────
  String get reviewScreenTitle;
  String get materialInfoLabel;
  String get unitInfoLabel;
  String get memoInfoLabel;
  String reviewCountLabel(int n);
  String get todayUnderstandingQuestion;

  // ── Stats ──────────────────────────────────────────────────
  String get statsTitle;
  String get summarySection;
  String get totalItemsLabel;
  String get todayReviewsLabel;
  String get totalReviewsLabel;
  String get itemsUnit;
  String get timesUnit;
  String get streakContinuing;
  String get streakDaysUnit;
  String get subjectSection;
  String get noDataYet;
  String subjectTouchLabel(String subject, int count);

  // ── Trash ──────────────────────────────────────────────────
  String get trashTitle;
  String get deleteAllAction;
  String get restoreAction;
  String get deleteAction;
  String get trashEmpty;
  String get trashEmptyHint;
  String get permanentDeleteTitle;
  String permanentDeleteContent(String subject, String unit);
  String get cancelButton;
  String emptyTrashContent(int n);
  String get deleteAllConfirmButton;
  String get restoredMessage;
  String deletedMinutesAgo(int n);
  String deletedHoursAgo(int n);
  String deletedDaysAgo(int n);

  // ── Settings ───────────────────────────────────────────────
  String get settingsTitle;
  String get themeSection;
  String get themeSystem;
  String get themeAlwaysDark;
  String get themeAlwaysLight;
  String get themeTimeBased;
  String themeTimeBasedSubtitle(String s, String e);
  String get themeSystemDesc;
  String get themeDarkDesc;
  String get themeLightDesc;
  String get themeTimeBasedDesc;
  String get darkStartLabel;
  String get lightReturnLabel;
  String get darkModeStartHelpText;
  String get lightModeReturnHelpText;
  String darkModeHoursDesc(String s, String e);
  String darkStartSetMsg(String h);
  String lightReturnSetMsg(String h);
  String get notificationsSection;
  String get dailyReminderTitle;
  String get dailyReminderSubtitle;
  String get notificationTimeLabel;
  String get notificationEnabledMsg;
  String get notificationDisabledMsg;
  String notificationTimeSetMsg(String h, String m);
  String get notificationNote;
  String get languageSection;
  String get languageJapanese;
  String get languageEnglish;
}

// ─────────────────────────────────────────────────────────────
// Delegate
// ─────────────────────────────────────────────────────────────
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ja', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'en':
        return AppLocalizationsEn();
      case 'ja':
      default:
        return AppLocalizationsJa();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
