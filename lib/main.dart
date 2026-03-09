import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/locale_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('A: binding OK');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('B: firebase OK');

  try {
    await NotificationService.initialize();
    debugPrint('C: notification init OK');
  } catch (e) {
    debugPrint('C: notification init FAILED: $e');
  }

  try {
    await NotificationService.rescheduleIfEnabled();
    debugPrint('D: notification reschedule OK');
  } catch (e) {
    debugPrint('D: notification reschedule FAILED: $e');
  }

  // テーマ設定を読み込む
  await ThemeService.initialize();
  debugPrint('F: theme init OK (${ThemeService.mode})');

  // ロケール設定を読み込む
  await LocaleService.initialize();
  debugPrint('G: locale init OK (${LocaleService.current.languageCode})');

  debugPrint('E: runApp start');
  runApp(const ReviewApp());
}

class ReviewApp extends StatelessWidget {
  const ReviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ロケールが変わるたびに MaterialApp を再ビルド（外側）
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.localeNotifier,
      builder: (context, locale, _) {
        // テーマが変わるたびに MaterialApp を再ビルド（内側）
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.themeNotifier,
          builder: (context, themeMode, _) {
            return MaterialApp(
              title: 'ReviewApp',
              debugShowCheckedModeBanner: false,

              // ── 多言語設定 ──────────────────────────────
              locale: locale,
              supportedLocales: const [
                Locale('ja'),
                Locale('en'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // ── テーマ設定 ──────────────────────────────
              theme: AppThemeLight.lightTheme,
              darkTheme: AppTheme.theme,
              themeMode: themeMode,

              home: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasData) {
                    return _DeactivationGate(user: snapshot.data!);
                  }
                  return LoginScreen();
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ── 無効化チェックゲート ────────────────────────────────

/// ログイン直後に users/{uid}.isDeactivated を確認するウィジェット。
/// true なら _DeactivatedScreen を、false なら HomeScreen を表示する。
class _DeactivationGate extends StatefulWidget {
  final User user;
  const _DeactivationGate({required this.user});

  @override
  State<_DeactivationGate> createState() => _DeactivationGateState();
}

class _DeactivationGateState extends State<_DeactivationGate> {
  late final Future<bool> _checkFuture;

  @override
  void initState() {
    super.initState();
    _checkFuture = _isDeactivated();
  }

  Future<bool> _isDeactivated() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      return doc.data()?['isDeactivated'] == true;
    } catch (_) {
      // Firestore アクセスエラー時はフェイルセーフでアクセスを許可
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkFuture,
      builder: (context, snapshot) {
        // チェック中はローディング
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // 無効化済み → 専用画面
        if (snapshot.data == true) return const _DeactivatedScreen();
        // 正常 → ホーム画面
        return HomeScreen();
      },
    );
  }
}

// ── 無効化済み表示画面 ──────────────────────────────────

class _DeactivatedScreen extends StatelessWidget {
  const _DeactivatedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // アイコン
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.dangerDim,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    size: 40,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 28),
                // メッセージ
                const Text(
                  'このアカウントは\n削除されています',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'ご不明な点は管理者にお問い合わせください。',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // ログイン画面へ戻るボタン（signOut → authStateChanges が LoginScreen に切り替え）
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ログイン画面へ戻る',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
