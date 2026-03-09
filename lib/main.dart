import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                  if (snapshot.hasData) return HomeScreen();
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
