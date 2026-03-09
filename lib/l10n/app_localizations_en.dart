import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  const AppLocalizationsEn();

  // ── Login ──────────────────────────────────────────────────
  @override String get loginTagline => 'Build your knowledge through consistent review';
  @override String get emailLabel => 'Email';
  @override String get passwordLabel => 'Password';
  @override String get loginButton => 'Log in';
  @override String get orDivider => 'or';
  @override String get createAccountButton => 'Create an account';
  @override String get loginErrorUserNotFound => 'Email address not found';
  @override String get loginErrorWrongPassword => 'Incorrect password';
  @override String get loginErrorInvalidEmail => 'Invalid email format';
  @override String get loginErrorTooManyRequests => 'Too many attempts. Please try again later';
  @override String loginErrorDefault(String code) => 'Login failed ($code)';

  // ── Signup ─────────────────────────────────────────────────
  @override String get signupScreenTitle => 'Create Account';
  @override String get signupHeading => 'Create your account';
  @override String get signupTagline => 'Get started for free';
  @override String get passwordMinHint => 'Password (min 6 characters)';
  @override String get signupButton => 'Create account';
  @override String get alreadyHaveAccount => 'Already have an account?';
  @override String get signupErrorEmailInUse => 'This email is already in use';
  @override String get signupErrorWeakPassword => 'Password must be at least 6 characters';
  @override String signupErrorDefault(String code) => 'Registration failed ($code)';

  // ── Home ───────────────────────────────────────────────────
  @override String get statisticsTooltip => 'Statistics';
  @override String get settingsTooltip => 'Settings';
  @override String get menuRefresh => 'Refresh';
  @override String get menuTrash => 'Trash';
  @override String get menuLogout => 'Log out';
  @override String get searchHint => 'Search by subject, material, unit';
  @override String get filterTodayLabel => 'Today';
  @override String get filterAllLabel => 'All';
  @override String get allSubjectsChip => 'All';
  @override String get materialAllChip => 'Material: All';
  @override String get sectionTodayReviews => "Today's Reviews";
  @override String get sectionAllItems => 'All Items';
  @override String get sortByDeadline => 'By deadline';
  @override String get sortBySubject => 'By subject';
  @override String get sortByNewest => 'Newest';
  @override String nItemsCount(int n) => '$n items';
  @override String selectedCount(int n) => '$n selected';
  @override String get selectAllAction => 'Select all';
  @override String get longPressToSelect => 'Long press to select';
  @override String get moveToTrashButton => 'Move to Trash';
  @override String movedToTrash(int n) => 'Moved $n item(s) to Trash';
  @override String get noFilterResults => 'No matching items';
  @override String get noFilterResultsHint => 'Try different search criteria';
  @override String get noItemsYet => 'Nothing registered yet';
  @override String get noItemsYetHint => 'Tap + to add your first item';
  @override String get allDoneToday => 'All reviews done for today!';
  @override String get allDoneTodayHint => 'Keep it up tomorrow!';
  @override String get streakStudying => 'on a learning streak';
  @override String streakDays(int n) => '$n-day streak';
  @override String get todayProgressDone => "Today's reviews complete!";
  @override String get todayProgressLabel => "Today's progress";
  @override String get noSchedule => 'None scheduled';
  @override String get overdueLabel => 'Overdue';
  @override String get todayLabel => 'Today';
  @override String reviewNthTime(int n) => '#$n';
  @override String get registerFab => 'Add';

  // ── AddReview ──────────────────────────────────────────────
  @override String get addReviewTitle => 'Add Review';
  @override String get saveAction => 'Save';
  @override String get basicInfoSection => 'Basic Info';
  @override String get subjectLabel => 'Subject *';
  @override String get subjectHint => 'e.g. Math, English, Physics';
  @override String get materialLabel => 'Material';
  @override String get materialHint => 'e.g. Textbook, Vocabulary list';
  @override String get unitLabel => 'Unit *';
  @override String get unitHint => 'e.g. Examples 12–18, Unit 5';
  @override String get memoSection => 'Notes';
  @override String get memoHint => 'Key points, weak areas...';
  @override String get understandingSection => "Today's Understanding";
  @override String get saveButton => 'Save';
  @override String get subjectUnitRequired => 'Subject and unit are required';
  @override String get understoodLabel => 'Got it';
  @override String get soSoLabel => 'So-so';
  @override String get notYetLabel => 'Not yet';
  @override String get nextIn3Days => 'Next in 3 days';
  @override String get nextIn2Days => 'Next in 2 days';
  @override String get nextTomorrow => 'Next: tomorrow';

  // ── Review ─────────────────────────────────────────────────
  @override String get reviewScreenTitle => 'Review';
  @override String get materialInfoLabel => 'Material';
  @override String get unitInfoLabel => 'Unit';
  @override String get memoInfoLabel => 'Notes';
  @override String reviewCountLabel(int n) => 'Review #$n';
  @override String get todayUnderstandingQuestion => 'How well did you understand?';

  // ── Stats ──────────────────────────────────────────────────
  @override String get statsTitle => 'Statistics';
  @override String get summarySection => 'Summary';
  @override String get totalItemsLabel => 'Total Items';
  @override String get todayReviewsLabel => "Today's Reviews";
  @override String get totalReviewsLabel => 'Total Reviews';
  @override String get itemsUnit => 'items';
  @override String get timesUnit => 'times';
  @override String get streakContinuing => 'Learning streak active';
  @override String get streakDaysUnit => '-day streak';
  @override String get subjectSection => 'By Subject';
  @override String get noDataYet => 'No data yet';
  @override String subjectTouchLabel(String subject, int count) =>
      '$subject  $count items';

  // ── Trash ──────────────────────────────────────────────────
  @override String get trashTitle => 'Trash';
  @override String get deleteAllAction => 'Delete all';
  @override String get restoreAction => 'Restore';
  @override String get deleteAction => 'Delete';
  @override String get trashEmpty => 'Trash is empty';
  @override String get trashEmptyHint => 'Deleted items will appear here';
  @override String get permanentDeleteTitle => 'Delete permanently';
  @override String permanentDeleteContent(String subject, String unit) =>
      '"$subject / $unit" will be permanently deleted.\nThis cannot be undone.';
  @override String get cancelButton => 'Cancel';
  @override String emptyTrashContent(int n) =>
      'Permanently delete all $n items?\nThis cannot be undone.';
  @override String get deleteAllConfirmButton => 'Delete all';
  @override String get restoredMessage => 'Restored';
  @override String deletedMinutesAgo(int n) => 'Deleted $n min ago';
  @override String deletedHoursAgo(int n) => 'Deleted ${n}h ago';
  @override String deletedDaysAgo(int n) => 'Deleted $n day(s) ago';

  // ── Settings ───────────────────────────────────────────────
  @override String get settingsTitle => 'Settings';
  @override String get themeSection => 'Theme';
  @override String get themeSystem => 'Follow system';
  @override String get themeAlwaysDark => 'Always dark';
  @override String get themeAlwaysLight => 'Always light';
  @override String get themeTimeBased => 'Auto by time';
  @override String themeTimeBasedSubtitle(String s, String e) =>
      'Auto ($s:00–$e:00)';
  @override String get themeSystemDesc => 'Uses iOS / system settings';
  @override String get themeDarkDesc => 'Dark themed display';
  @override String get themeLightDesc => 'Light themed display';
  @override String get themeTimeBasedDesc => 'Dark during specified hours';
  @override String get darkStartLabel => 'Dark starts';
  @override String get lightReturnLabel => 'Light returns';
  @override String get darkModeStartHelpText => 'Dark mode start time';
  @override String get lightModeReturnHelpText => 'Light mode return time';
  @override String darkModeHoursDesc(String s, String e) =>
      '$s:00 – $e:00 is dark mode';
  @override String darkStartSetMsg(String h) => 'Dark mode starts at $h:00';
  @override String lightReturnSetMsg(String h) => 'Light mode returns at $h:00';
  @override String get notificationsSection => 'Notifications';
  @override String get dailyReminderTitle => 'Daily review reminder';
  @override String get dailyReminderSubtitle => 'Notifies at the set time';
  @override String get notificationTimeLabel => 'Notification time';
  @override String get notificationEnabledMsg => 'Notifications enabled';
  @override String get notificationDisabledMsg => 'Notifications disabled';
  @override String notificationTimeSetMsg(String h, String m) =>
      'Notification time set to $h:$m';
  @override String get notificationNote =>
      '* Notifications work on iOS / Android devices.\nNot available in browser (Chrome).';
  @override String get languageSection => 'Language';
  @override String get languageJapanese => '日本語';
  @override String get languageEnglish => 'English';
}
