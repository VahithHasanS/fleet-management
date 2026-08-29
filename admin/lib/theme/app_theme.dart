import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FleetSafe dark theme — deep navy surfaces with blue/violet accent palette
/// matching the UI design guide exactly.
class AppColors {
  AppColors._();

  // Primary backgrounds
  static const Color bg = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceAlt = Color(0xFF162031);
  static const Color border = Color(0xFF334155);

  // Accent / brand
  static const Color accent = Color(0xFF2563EB);
  static const Color accentDark = Color(0xFF1E40AF);
  static const Color accentLight = Color(0xFF3B82F6);

  // Purple / violet
  static const Color violet = Color(0xFF8B5CF6);

  // Text
  static const Color text = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status
  static const Color green = Color(0xFF22C55E);
  static const Color amber = Color(0xFFF59E0B);
  static const Color orange = Color(0xFFF97316);
  static const Color red = Color(0xFFEF4444);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color teal = Color(0xFF10B981);

  // Severity
  static const Color severityLow = Color(0xFF22C55E);
  static const Color severityMedium = Color(0xFFF59E0B);
  static const Color severityHigh = Color(0xFFF97316);
  static const Color severityCritical = Color(0xFFEF4444);

  // Chart palette
  static const List<Color> chartPalette = [
    Color(0xFF2563EB),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF22D3EE),
    Color(0xFFF97316),
    Color(0xFF64748B),
  ];

  static Color severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return severityCritical;
      case 'high':
        return severityHigh;
      case 'medium':
        return severityMedium;
      case 'low':
      default:
        return severityLow;
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'in_transit':
        return green;
      case 'online':
        return green;
      case 'idle':
        return accent;
      case 'on_break':
        return amber;
      case 'maintenance':
        return red;
      case 'offline':
      default:
        return textMuted;
    }
  }

  static Color roleColor(String? colorHex) {
    if (colorHex == null) return accent;
    final hex = colorHex.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return accent;
    return Color(0xFF000000 | value);
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.violet,
        surface: AppColors.surface,
        error: AppColors.red,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.surface),
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
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceAlt,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.text),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: TextStyle(color: AppColors.text),
      ),
    );
  }
}
