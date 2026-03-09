import 'app_localizations.dart';

class AppLocalizationsJa extends AppLocalizations {
  const AppLocalizationsJa();

  // ── Login ──────────────────────────────────────────────────
  @override String get loginTagline => '復習で学力を確実に伸ばそう';
  @override String get emailLabel => 'メールアドレス';
  @override String get passwordLabel => 'パスワード';
  @override String get loginButton => 'ログイン';
  @override String get orDivider => 'または';
  @override String get createAccountButton => 'アカウントを作成する';
  @override String get loginErrorUserNotFound => 'メールアドレスが見つかりません';
  @override String get loginErrorWrongPassword => 'パスワードが間違っています';
  @override String get loginErrorInvalidEmail => 'メールアドレスの形式が正しくありません';
  @override String get loginErrorTooManyRequests => 'しばらく待ってから再試行してください';
  @override String loginErrorDefault(String code) => 'ログインに失敗しました（$code）';

  // ── Signup ─────────────────────────────────────────────────
  @override String get signupScreenTitle => 'アカウント作成';
  @override String get signupHeading => 'アカウントを作成';
  @override String get signupTagline => '無料で今すぐ始めよう';
  @override String get passwordMinHint => 'パスワード（6文字以上）';
  @override String get signupButton => 'アカウントを作成する';
  @override String get alreadyHaveAccount => 'すでにアカウントをお持ちの方';
  @override String get signupErrorEmailInUse => 'このメールアドレスはすでに使用されています';
  @override String get signupErrorWeakPassword => 'パスワードは6文字以上にしてください';
  @override String signupErrorDefault(String code) => '登録に失敗しました（$code）';

  // ── Home ───────────────────────────────────────────────────
  @override String get statisticsTooltip => '統計';
  @override String get settingsTooltip => '設定';
  @override String get menuRefresh => '更新';
  @override String get menuTrash => 'ゴミ箱';
  @override String get menuLogout => 'ログアウト';
  @override String get searchHint => '科目・教材・範囲で検索';
  @override String get filterTodayLabel => '今日';
  @override String get filterAllLabel => '全件';
  @override String get allSubjectsChip => 'すべて';
  @override String get materialAllChip => '教材: すべて';
  @override String get sectionTodayReviews => '今日の復習';
  @override String get sectionAllItems => '全件';
  @override String get sortByDeadline => '期限順';
  @override String get sortBySubject => '科目順';
  @override String get sortByNewest => '新着順';
  @override String nItemsCount(int n) => '$n件';
  @override String selectedCount(int n) => '$n件選択中';
  @override String get selectAllAction => '全選択';
  @override String get longPressToSelect => '長押しで選択';
  @override String get moveToTrashButton => 'ゴミ箱へ移動';
  @override String movedToTrash(int n) => '$n件をゴミ箱に移動しました';
  @override String get noFilterResults => '該当する項目がありません';
  @override String get noFilterResultsHint => '検索条件を変えてみてください';
  @override String get noItemsYet => 'まだ登録がありません';
  @override String get noItemsYetHint => '＋ボタンから追加しましょう';
  @override String get allDoneToday => '今日の復習はすべて完了！';
  @override String get allDoneTodayHint => '明日もがんばろう';
  @override String get streakStudying => '学習中です';
  @override String streakDays(int n) => '$n日連続';
  @override String get todayProgressDone => '今日の復習が完了！';
  @override String get todayProgressLabel => '今日の進捗';
  @override String get noSchedule => '予定なし';
  @override String get overdueLabel => '超過';
  @override String get todayLabel => '今日';
  @override String reviewNthTime(int n) => '$n回目';
  @override String get registerFab => '登録';

  // ── AddReview ──────────────────────────────────────────────
  @override String get addReviewTitle => '復習を登録';
  @override String get saveAction => '保存';
  @override String get basicInfoSection => '基本情報';
  @override String get subjectLabel => '科目 *';
  @override String get subjectHint => '例：数学、英語、物理';
  @override String get materialLabel => '教材名';
  @override String get materialHint => '例：青チャート、システム英単語';
  @override String get unitLabel => '範囲 *';
  @override String get unitHint => '例：例題12〜18、Unit 5';
  @override String get memoSection => 'メモ';
  @override String get memoHint => '気づきや苦手ポイントなど...';
  @override String get understandingSection => '今日の理解度';
  @override String get saveButton => '保存する';
  @override String get subjectUnitRequired => '科目と範囲は必須です';
  @override String get understoodLabel => 'できた';
  @override String get soSoLabel => '微妙';
  @override String get notYetLabel => 'できない';
  @override String get nextIn3Days => '次回は3日後';
  @override String get nextIn2Days => '次回は2日後';
  @override String get nextTomorrow => '次回は明日';

  // ── Review ─────────────────────────────────────────────────
  @override String get reviewScreenTitle => '復習';
  @override String get materialInfoLabel => '教材';
  @override String get unitInfoLabel => '範囲';
  @override String get memoInfoLabel => 'メモ';
  @override String reviewCountLabel(int n) => '$n回目の復習';
  @override String get todayUnderstandingQuestion => '今日の理解度は？';

  // ── Stats ──────────────────────────────────────────────────
  @override String get statsTitle => '学習統計';
  @override String get summarySection => 'サマリー';
  @override String get totalItemsLabel => '総登録数';
  @override String get todayReviewsLabel => '今日の復習';
  @override String get totalReviewsLabel => '総復習回数';
  @override String get itemsUnit => '件';
  @override String get timesUnit => '回';
  @override String get streakContinuing => '学習ストリーク継続中';
  @override String get streakDaysUnit => '日連続';
  @override String get subjectSection => '科目別';
  @override String get noDataYet => 'まだデータがありません';
  @override String subjectTouchLabel(String subject, int count) => '$subject  $count件';

  // ── Trash ──────────────────────────────────────────────────
  @override String get trashTitle => 'ゴミ箱';
  @override String get deleteAllAction => 'すべて削除';
  @override String get restoreAction => '復元';
  @override String get deleteAction => '削除';
  @override String get trashEmpty => 'ゴミ箱は空です';
  @override String get trashEmptyHint => '削除した記録はここに表示されます';
  @override String get permanentDeleteTitle => '完全に削除';
  @override String permanentDeleteContent(String subject, String unit) =>
      '「$subject / $unit」を完全に削除しますか？\nこの操作は元に戻せません。';
  @override String get cancelButton => 'キャンセル';
  @override String emptyTrashContent(int n) =>
      '${n}件のアイテムをすべて完全に削除しますか？\nこの操作は元に戻せません。';
  @override String get deleteAllConfirmButton => 'すべて削除';
  @override String get restoredMessage => '復元しました';
  @override String deletedMinutesAgo(int n) => '$n分前に削除';
  @override String deletedHoursAgo(int n) => '$n時間前に削除';
  @override String deletedDaysAgo(int n) => '$n日前に削除';

  // ── Settings ───────────────────────────────────────────────
  @override String get settingsTitle => '設定';
  @override String get themeSection => 'テーマ';
  @override String get themeSystem => 'システム設定に従う';
  @override String get themeAlwaysDark => '常にダーク';
  @override String get themeAlwaysLight => '常にライト';
  @override String get themeTimeBased => '時間帯で自動';
  @override String themeTimeBasedSubtitle(String s, String e) =>
      '時間帯で自動（$s:00〜$e:00）';
  @override String get themeSystemDesc => 'iOSの設定を使用';
  @override String get themeDarkDesc => '黒ベースの表示';
  @override String get themeLightDesc => '白ベースの表示';
  @override String get themeTimeBasedDesc => '指定した時間帯にダーク';
  @override String get darkStartLabel => 'ダーク開始';
  @override String get lightReturnLabel => 'ライト復帰';
  @override String get darkModeStartHelpText => 'ダークモード開始時刻';
  @override String get lightModeReturnHelpText => 'ライトモード復帰時刻';
  @override String darkModeHoursDesc(String s, String e) =>
      '$s:00 〜 $e:00 がダークモード';
  @override String darkStartSetMsg(String h) => 'ダーク開始を $h:00 に設定しました';
  @override String lightReturnSetMsg(String h) => 'ライト復帰を $h:00 に設定しました';
  @override String get notificationsSection => '通知設定';
  @override String get dailyReminderTitle => '毎日の復習リマインダー';
  @override String get dailyReminderSubtitle => '指定した時刻に通知します';
  @override String get notificationTimeLabel => '通知時刻';
  @override String get notificationEnabledMsg => '通知をONにしました';
  @override String get notificationDisabledMsg => '通知をOFFにしました';
  @override String notificationTimeSetMsg(String h, String m) =>
      '通知時刻を $h:$m に設定しました';
  @override String get notificationNote =>
      '※ 通知はiOS / Android実機で動作します。\nブラウザ（Chrome）では通知は届きません。';
  @override String get languageSection => '言語';
  @override String get languageJapanese => '日本語';
  @override String get languageEnglish => 'English';
}
