import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ─── Brand Identity ───────────────────────────────────────────────────────
  // Deep space midnight base
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF0A2D6E);

  // Electric cyan accent — command & control
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentLight = Color(0xFF80F7FF);
  static const Color accentDark = Color(0xFF00B8D4);

  // Crisis Red — SOS urgency
  static const Color sos = Color(0xFFFF1744);
  static const Color sosLight = Color(0xFFFF616F);
  static const Color sosDark = Color(0xFFD50000);

  // Amber — help requests
  static const Color help = Color(0xFFFF9100);
  static const Color helpLight = Color(0xFFFFBF45);
  static const Color helpDark = Color(0xFFE65100);

  // Emerald — available / success
  static const Color success = Color(0xFF00E676);
  static const Color successLight = Color(0xFF69F0AE);
  static const Color successDark = Color(0xFF00C853);

  // Warning
  static const Color warning = Color(0xFFFFD740);

  // ─── Backgrounds (deep space) ─────────────────────────────────────────────
  static const Color background = Color(0xFF05080F);
  static const Color surface = Color(0xFF0C1220);
  static const Color surfaceVariant = Color(0xFF131D30);
  static const Color cardColor = Color(0xFF111827);
  static const Color cardAlt = Color(0xFF0F1A2E);

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F6FF);
  static const Color textSecondary = Color(0xFF8FA8CC);
  static const Color textHint = Color(0xFF4A6080);
  static const Color textAccent = Color(0xFF00E5FF);

  // ─── Borders & Dividers ───────────────────────────────────────────────────
  static const Color border = Color(0xFF1E3050);
  static const Color borderGlow = Color(0xFF1E88E5);
  static const Color divider = Color(0xFF162035);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0A2D6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sosGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFF7B0020)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient helpGradient = LinearGradient(
    colors: [Color(0xFFFF9100), Color(0xFFBF360C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF05080F), Color(0xFF0C1220), Color(0xFF080D1A)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF0C1422)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF0C1220), Color(0xFF0A1830)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Glow / Shadow helpers ─────────────────────────────────────────────────
  static List<BoxShadow> glowAccent({double intensity = 0.4, double blur = 24}) =>
      [BoxShadow(color: accent.withValues(alpha: intensity), blurRadius: blur, spreadRadius: 2)];

  static List<BoxShadow> glowSos({double intensity = 0.45, double blur = 28}) =>
      [BoxShadow(color: sos.withValues(alpha: intensity), blurRadius: blur, spreadRadius: 4)];

  static List<BoxShadow> glowPrimary({double intensity = 0.35, double blur = 20}) =>
      [BoxShadow(color: primary.withValues(alpha: intensity), blurRadius: blur, spreadRadius: 2)];

  static List<BoxShadow> glowSuccess({double intensity = 0.4, double blur = 20}) =>
      [BoxShadow(color: success.withValues(alpha: intensity), blurRadius: blur, spreadRadius: 2)];

  static List<BoxShadow> cardShadow() => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.sos,
        onPrimary: Colors.white,
        onSecondary: AppColors.background,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
        tertiary: AppColors.success,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.cardColor,
      dividerColor: AppColors.divider,

      // ─── Typography ─────────────────────────────────────────────────────
      // Heading: Rajdhani – military/command feel, geometric & bold
      // Body/UI: DM Sans – clean, modern, highly legible
      textTheme: base.textTheme
          .copyWith(
            // Display — hero numbers/titles
            displayLarge: GoogleFonts.rajdhani(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.1,
            ),
            displayMedium: GoogleFonts.rajdhani(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
            displaySmall: GoogleFonts.rajdhani(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            // Headlines
            headlineLarge: GoogleFonts.rajdhani(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
            headlineMedium: GoogleFonts.rajdhani(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            headlineSmall: GoogleFonts.rajdhani(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            // Titles — DM Sans for UI labels
            titleLarge: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            titleMedium: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            titleSmall: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            // Body
            bodyLarge: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
            bodyMedium: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            bodySmall: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textHint,
            ),
            // Labels
            labelLarge: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.6,
            ),
            labelMedium: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
            labelSmall: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
              letterSpacing: 0.8,
            ),
          ),

      // ─── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.rajdhani(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ─── Buttons ──────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Inputs ───────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.sos, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.sos, width: 2),
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textHint,
        ),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        errorStyle: GoogleFonts.dmSans(
          fontSize: 12,
          color: AppColors.sos,
        ),
      ),

      // ─── Chips ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primaryLight,
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),

      // ─── Switch ───────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.success;
          return AppColors.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.successLight.withValues(alpha: 0.35);
          }
          return AppColors.border;
        }),
      ),

      // ─── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariant,
        contentTextStyle: GoogleFonts.dmSans(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),

      // ─── Bottom Nav ───────────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ─── Progress ─────────────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),

      // ─── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.rajdhani(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),

      // ─── ListTile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        subtitleTextStyle: GoogleFonts.dmSans(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        iconColor: AppColors.accent,
      ),
    );
  }
}
