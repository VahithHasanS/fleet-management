import 'package:flutter/material.dart';

/// Ghost Telemetry dark theme — deep navy surfaces with blue/violet accents
/// (matches the UI design guide). Tuned for the driver app: large touch
/// targets, high-contrast cards.
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF070B14);
  static const Color surface = Color(0xFF0F1626);
  static const Color surfaceAlt = Color(0xFF162031);
  static const Color border = Color(0xFF22304a);
  static const Color accent = Color(0xFF2F6BFF);
  static const Color accentLight = Color(0xFF5B8CFF);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color text = Color(0xFFE8EEF9);
  static const Color textMuted = Color(0xFF8CA0BC);
  static const Color green = Color(0xFF22C55E);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color cyan = Color(0xFF22D3EE);

  static Color severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return red;
      case 'high':
        return Color(0xFFF97316);
      case 'medium':
        return amber;
      case 'low':
      default:
        return green;
    }
  }

  static Color scoreColor(int score) {
    if (score >= 90) return green;
    if (score >= 75) return cyan;
    if (score >= 60) return amber;
    return red;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.violet,
        surface: AppColors.surface,
        error: AppColors.red,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.25),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.accentLight
                  : AppColors.textMuted,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            TextStyle(
              fontSize: 12,
              color: states.contains(WidgetState.selected)
                  ? AppColors.accentLight
                  : AppColors.textMuted,
            )),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentLight,
          side: const BorderSide(color: AppColors.accent),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: TextStyle(color: AppColors.text),
      ),
    );
  }
}
