import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class FitNexoraThemeTokens extends ThemeExtension<FitNexoraThemeTokens> {
  final Color brand;
  final Color brandSecondary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceMuted;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color glassFill;
  final Color glassBorder;
  final Color glow;
  final Color ringTrack;

  const FitNexoraThemeTokens({
    required this.brand,
    required this.brandSecondary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceMuted,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.glassFill,
    required this.glassBorder,
    required this.glow,
    required this.ringTrack,
  });

  factory FitNexoraThemeTokens.dark() => const FitNexoraThemeTokens(
        brand: Color(0xFF895AF6),
        brandSecondary: Color(0xFFBA98FF),
        accent: Color(0xFF10D88A),
        success: Color(0xFF10D88A),
        warning: Color(0xFFF6B546),
        danger: Color(0xFFFF6B7D),
        info: Color(0xFF7A8BFF),
        background: Color(0xFF0B0714),
        backgroundAlt: Color(0xFF171126),
        surface: Color(0xFF151022),
        surfaceAlt: Color(0xFF1E1730),
        surfaceMuted: Color(0xFF2A2140),
        border: Color(0xFF2E2648),
        divider: Color(0xFF261F3D),
        textPrimary: Color(0xFFF8F7FD),
        textSecondary: Color(0xFFB3A9CC),
        textMuted: Color(0xFF7E7597),
        glassFill: Color(0x2EF8F7FD),
        glassBorder: Color(0x3DFFFFFF),
        glow: Color(0x40895AF6),
        ringTrack: Color(0xFF29203F),
      );

  factory FitNexoraThemeTokens.light() => const FitNexoraThemeTokens(
        brand: Color(0xFF895AF6),
        brandSecondary: Color(0xFFB895FF),
        accent: Color(0xFF1FD493),
        success: Color(0xFF1DBF82),
        warning: Color(0xFFF2B451),
        danger: Color(0xFFE9697A),
        info: Color(0xFF6A7BFF),
        background: Color(0xFFF7F5FB),
        backgroundAlt: Color(0xFFF0ECF7),
        surface: Color(0xFFFFFFFF),
        surfaceAlt: Color(0xFFF7F3FD),
        surfaceMuted: Color(0xFFF2EDF9),
        border: Color(0xFFE7E0F5),
        divider: Color(0xFFEDE7F8),
        textPrimary: Color(0xFF221A36),
        textSecondary: Color(0xFF6E6489),
        textMuted: Color(0xFFA098B6),
        glassFill: Color(0xCCFFFFFF),
        glassBorder: Color(0x4DFFFFFF),
        glow: Color(0x33895AF6),
        ringTrack: Color(0xFFE8E1F4),
      );

  LinearGradient get brandGradient => LinearGradient(
        colors: [brand, brandSecondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get heroGradient => LinearGradient(
        colors: [brand.withOpacity(0.24), accent.withOpacity(0.14)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  @override
  FitNexoraThemeTokens copyWith({
    Color? brand,
    Color? brandSecondary,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? background,
    Color? backgroundAlt,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceMuted,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? glassFill,
    Color? glassBorder,
    Color? glow,
    Color? ringTrack,
  }) {
    return FitNexoraThemeTokens(
      brand: brand ?? this.brand,
      brandSecondary: brandSecondary ?? this.brandSecondary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      background: background ?? this.background,
      backgroundAlt: backgroundAlt ?? this.backgroundAlt,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      glow: glow ?? this.glow,
      ringTrack: ringTrack ?? this.ringTrack,
    );
  }

  @override
  FitNexoraThemeTokens lerp(
    ThemeExtension<FitNexoraThemeTokens>? other,
    double t,
  ) {
    if (other is! FitNexoraThemeTokens) return this;
    return FitNexoraThemeTokens(
      brand: Color.lerp(brand, other.brand, t)!,
      brandSecondary: Color.lerp(brandSecondary, other.brandSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      background: Color.lerp(background, other.background, t)!,
      backgroundAlt: Color.lerp(backgroundAlt, other.backgroundAlt, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      ringTrack: Color.lerp(ringTrack, other.ringTrack, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    tokens: FitNexoraThemeTokens.dark(),
  );

  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    tokens: FitNexoraThemeTokens.light(),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required FitNexoraThemeTokens tokens,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: tokens.brand,
      brightness: brightness,
      surface: tokens.surface,
      primary: tokens.brand,
      secondary: tokens.accent,
      error: tokens.danger,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      splashFactory: InkRipple.splashFactory,
      extensions: [tokens],
    );
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        color: tokens.textPrimary,
        letterSpacing: -1.6,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: tokens.textPrimary,
        letterSpacing: -1.1,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: tokens.textPrimary,
        letterSpacing: -0.6,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: tokens.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: tokens.textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: tokens.textMuted,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
      ),
    );

    return base.copyWith(
      primaryColor: tokens.brand,
      textTheme: textTheme,
      dividerColor: tokens.divider,
      iconTheme: IconThemeData(color: tokens.textSecondary),
      cardColor: tokens.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: tokens.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: tokens.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? tokens.surfaceAlt : tokens.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        prefixIconColor: tokens.textMuted,
        suffixIconColor: tokens.textMuted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: tokens.brand, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: tokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: tokens.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          side: BorderSide(color: tokens.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.brand,
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.surfaceAlt,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tokens.surface,
        selectedItemColor: tokens.brand,
        unselectedItemColor: tokens.textMuted,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.brand,
        linearTrackColor: tokens.ringTrack,
        circularTrackColor: tokens.ringTrack,
      ),
    );
  }
}
