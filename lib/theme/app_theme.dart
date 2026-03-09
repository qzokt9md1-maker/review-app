import 'package:flutter/material.dart';

// ────────────────────────────────────────────────────────────
// Nordic Dark  ディープネイビー × ペールブルー
// bg #1A1F2E  surface #222A3C  accent #7FB0CC  text #E8EAF0
// ────────────────────────────────────────────────────────────
class AppColors {
  // 背景・サーフェス
  static const background    = Color(0xFF1A1F2E); // Deep Navy
  static const surface       = Color(0xFF222A3C); // Dark Steel
  static const surfaceHigh   = Color(0xFF2B3450); // Elevated
  static const overlay       = Color(0xFF333F5A); // Panel / Modal

  // アクセント（Nordic Pale Blue）
  static const primary       = Color(0xFF7FB0CC); // Pale Blue
  static const primaryDim    = Color(0xFF1C2A3A); // Dark tinted
  static const primaryMid    = Color(0xFF243344); // Mid tint

  // テキスト
  static const textPrimary   = Color(0xFFE8EAF0); // Off-white (cool)
  static const textSecondary = Color(0xFF7A8BA0); // Steel gray
  static const textHint      = Color(0xFF4A5870); // Dark hint
  static const textOnDim     = Color(0xFFAAB8C8); // dim背景上サブテキスト

  // ボーダー
  static const border        = Color(0xFF2E3A50);
  static const borderFocus   = Color(0xFF7FB0CC);

  // ステータス
  static const success       = Color(0xFF6AB090); // Sage
  static const successDim    = Color(0xFF1B2D28);
  static const warning       = Color(0xFFB09060); // Warm muted
  static const warningDim    = Color(0xFF2A2518);
  static const danger        = Color(0xFFC07070); // Muted coral
  static const dangerDim     = Color(0xFF2E1E1E);

  // 科目カラー（Nordic：落ち着いた寒色〜中間色）
  static const subjectColors = [
    Color(0xFF7FB0CC), // Pale Blue
    Color(0xFF6AB090), // Sage Green
    Color(0xFF8890C4), // Periwinkle
    Color(0xFFB09090), // Dusty Rose
    Color(0xFF7AA8B0), // Steel Teal
    Color(0xFF9098C0), // Slate Blue
  ];
}

// ── テキストスタイル ────────────────────────────────────
class AppTextStyles {
  static const _fallback = [
    'SF Pro Display', 'SF Pro Text',
    'Hiragino Sans', 'Yu Gothic',
    'Noto Sans JP', 'Meiryo', 'sans-serif',
  ];

  static const heading1 = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFamilyFallback: _fallback,
  );
  static const heading2 = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    fontFamilyFallback: _fallback,
  );
  static const body = TextStyle(
    fontSize: 15,
    height: 1.6, fontFamilyFallback: _fallback,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontFamilyFallback: _fallback,
  );
  static const label = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    fontFamilyFallback: _fallback,
  );
}

// ── ダークテーマ ────────────────────────────────────────
class AppTheme {
  static const _fallback = [
    'SF Pro Display', 'SF Pro Text',
    'Hiragino Sans', 'Yu Gothic',
    'Noto Sans JP', 'Meiryo', 'sans-serif',
  ];

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.primary,
        secondary: AppColors.primary,
        surface:   AppColors.surface,
        error:     AppColors.danger,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError:   Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,

      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontFamilyFallback: _fallback),
        displayMedium:  TextStyle(fontFamilyFallback: _fallback),
        displaySmall:   TextStyle(fontFamilyFallback: _fallback),
        headlineLarge:  TextStyle(fontFamilyFallback: _fallback),
        headlineMedium: TextStyle(fontFamilyFallback: _fallback),
        headlineSmall:  TextStyle(fontFamilyFallback: _fallback),
        titleLarge:     TextStyle(fontFamilyFallback: _fallback),
        titleMedium:    TextStyle(fontFamilyFallback: _fallback),
        titleSmall:     TextStyle(fontFamilyFallback: _fallback),
        bodyLarge:      TextStyle(fontFamilyFallback: _fallback, color: AppColors.textPrimary),
        bodyMedium:     TextStyle(fontFamilyFallback: _fallback, color: AppColors.textPrimary),
        bodySmall:      TextStyle(fontFamilyFallback: _fallback, color: AppColors.textSecondary),
        labelLarge:     TextStyle(fontFamilyFallback: _fallback),
        labelMedium:    TextStyle(fontFamilyFallback: _fallback),
        labelSmall:     TextStyle(fontFamilyFallback: _fallback),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -0.3,
          fontFamilyFallback: _fallback,
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),

      // Card: 角丸を小さく・シャドウ有り
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 3,
        shadowColor: Color(0xFF080C18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            fontFamilyFallback: _fallback,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamilyFallback: _fallback),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontFamilyFallback: _fallback),
        hintStyle: const TextStyle(color: AppColors.textHint, fontFamilyFallback: _fallback),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border, thickness: 0.5,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.overlay,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary, fontFamilyFallback: _fallback),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.overlay,
        textStyle: TextStyle(color: AppColors.textPrimary, fontFamilyFallback: _fallback),
      ),
    );
  }
}

// ── 共通ウィジェット ────────────────────────────────────

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title.toUpperCase(), style: AppTextStyles.label);
  }
}

/// Nordic カード（やや角張り + ソフトシャドウ）
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({super.key, required this.child, this.padding, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? (isDark ? AppColors.surface : AppLightColors.surface);
    final shadowColor = isDark
        ? const Color(0xFF080C18).withOpacity(0.5)
        : const Color(0xFF6A7A90).withOpacity(0.1);
    final shadowColor2 = isDark
        ? const Color(0xFF080C18).withOpacity(0.25)
        : const Color(0xFF6A7A90).withOpacity(0.05);
    final borderColor = isDark
        ? AppColors.border.withOpacity(0.6)
        : AppLightColors.border.withOpacity(0.9);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 12, offset: const Offset(0, 3)),
          BoxShadow(color: shadowColor2, blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: AppColors.primary.withOpacity(0.06),
          highlightColor: AppColors.primary.withOpacity(0.03),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SubjectBadge extends StatelessWidget {
  final String subject;
  final int colorIndex;
  const SubjectBadge({super.key, required this.subject, this.colorIndex = 0});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.subjectColors[colorIndex % AppColors.subjectColors.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.35), width: 0.5),
      ),
      child: Text(
        subject,
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: color,
          letterSpacing: 0.1,
          fontFamilyFallback: AppTextStyles._fallback,
        ),
      ),
    );
  }
}

class UnderstandingBadge extends StatelessWidget {
  final String understanding;
  const UnderstandingBadge({super.key, required this.understanding});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (understanding) {
      case 'できた':
        color = AppColors.success; icon = Icons.check_circle_outline; break;
      case '微妙':
        color = AppColors.warning; icon = Icons.help_outline; break;
      default:
        color = AppColors.danger;  icon = Icons.cancel_outlined;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          understanding,
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color,
            fontFamilyFallback: AppTextStyles._fallback,
          ),
        ),
      ],
    );
  }
}

// ── ライトテーマ  Nordic Light  オフホワイト × スチールブルー ──
class AppLightColors {
  static const background    = Color(0xFFF0F2F5); // Cool off-white
  static const surface       = Color(0xFFFFFFFF); // White
  static const surfaceHigh   = Color(0xFFE8EBF0); // Light blue-gray
  static const overlay       = Color(0xFFD8DCE8); // Panel
  static const primary       = Color(0xFF4A7FA0); // Nordic Blue
  static const primaryDim    = Color(0xFFE4EDF5); // Light tinted blue
  static const textPrimary   = Color(0xFF1A2535); // Deep navy
  static const textSecondary = Color(0xFF6A7A90); // Steel gray
  static const textHint      = Color(0xFFA0AEBB); // Light hint
  static const border        = Color(0xFFCDD4E0); // Cool gray
  static const borderFocus   = Color(0xFF4A7FA0);
  static const success       = Color(0xFF3A8A60);
  static const successDim    = Color(0xFFE0F2EC);
  static const warning       = Color(0xFF8A7040);
  static const warningDim    = Color(0xFFF5EFE0);
  static const danger        = Color(0xFFAA4040);
  static const dangerDim     = Color(0xFFFFEEEE);
}

class AppThemeLight {
  static const _fallback = [
    'SF Pro Display', 'SF Pro Text',
    'Hiragino Sans', 'Yu Gothic',
    'Noto Sans JP', 'Meiryo', 'sans-serif',
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary:   AppLightColors.primary,
        secondary: AppLightColors.primary,
        surface:   AppLightColors.surface,
        error:     AppLightColors.danger,
        onPrimary: Colors.white,
        onSurface: AppLightColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppLightColors.background,
      textTheme: const TextTheme(
        bodyLarge:      TextStyle(fontFamilyFallback: _fallback, color: AppLightColors.textPrimary),
        bodyMedium:     TextStyle(fontFamilyFallback: _fallback, color: AppLightColors.textPrimary),
        bodySmall:      TextStyle(fontFamilyFallback: _fallback, color: AppLightColors.textSecondary),
        displayLarge:   TextStyle(fontFamilyFallback: _fallback),
        displayMedium:  TextStyle(fontFamilyFallback: _fallback),
        displaySmall:   TextStyle(fontFamilyFallback: _fallback),
        headlineLarge:  TextStyle(fontFamilyFallback: _fallback),
        headlineMedium: TextStyle(fontFamilyFallback: _fallback),
        headlineSmall:  TextStyle(fontFamilyFallback: _fallback),
        titleLarge:     TextStyle(fontFamilyFallback: _fallback),
        titleMedium:    TextStyle(fontFamilyFallback: _fallback),
        titleSmall:     TextStyle(fontFamilyFallback: _fallback),
        labelLarge:     TextStyle(fontFamilyFallback: _fallback),
        labelMedium:    TextStyle(fontFamilyFallback: _fallback),
        labelSmall:     TextStyle(fontFamilyFallback: _fallback),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppLightColors.background,
        foregroundColor: AppLightColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: AppLightColors.textPrimary, letterSpacing: -0.3,
          fontFamilyFallback: _fallback,
        ),
        iconTheme: IconThemeData(color: AppLightColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppLightColors.surface,
        elevation: 2,
        shadowColor: Color(0xFF6A7A90),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppLightColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            fontFamilyFallback: _fallback,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppLightColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamilyFallback: _fallback),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppLightColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppLightColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppLightColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppLightColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppLightColors.textSecondary, fontFamilyFallback: _fallback),
        hintStyle: const TextStyle(color: AppLightColors.textSecondary, fontFamilyFallback: _fallback),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppLightColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppLightColors.border, thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppLightColors.overlay,
        contentTextStyle: const TextStyle(color: AppLightColors.textPrimary, fontFamilyFallback: _fallback),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppLightColors.surface,
        textStyle: TextStyle(color: AppLightColors.textPrimary, fontFamilyFallback: _fallback),
      ),
    );
  }
}
