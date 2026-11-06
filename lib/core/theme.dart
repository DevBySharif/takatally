import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The warm, tactile brand palette used across Taka Counter.
@immutable
class TakaPalette extends ThemeExtension<TakaPalette> {
  const TakaPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.inkSoft,
    required this.line,
    required this.forest,
    required this.forestDeep,
    required this.lime,
    required this.limeSoft,
    required this.gold,
    required this.goldSoft,
    required this.coral,
    required this.coralSoft,
    required this.skySoft,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color ink;
  final Color inkSoft;
  final Color line;
  final Color forest;
  final Color forestDeep;
  final Color lime;
  final Color limeSoft;
  final Color gold;
  final Color goldSoft;
  final Color coral;
  final Color coralSoft;
  final Color skySoft;
  final Color shadow;

  bool get isDark => background.computeLuminance() < 0.2;

  /// Brand green that stays legible on both the cream and the dark canvas.
  Color get accent => isDark ? lime : forest;

  static const light = TakaPalette(
    background: Color(0xFFF5F3EC),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEECE4),
    ink: Color(0xFF14241C),
    inkSoft: Color(0xFF68736C),
    line: Color(0xFFE4E0D6),
    forest: Color(0xFF173F2E),
    forestDeep: Color(0xFF0E2A1E),
    lime: Color(0xFFC7F36B),
    limeSoft: Color(0xFFEAF7CC),
    gold: Color(0xFFF1C75B),
    goldSoft: Color(0xFFFCF1D2),
    coral: Color(0xFFE56A52),
    coralSoft: Color(0xFFFBE6E1),
    skySoft: Color(0xFFE5EEEC),
    shadow: Color(0x140E2A1E),
  );

  static const dark = TakaPalette(
    background: Color(0xFF0C1611),
    surface: Color(0xFF14221A),
    surfaceMuted: Color(0xFF1C2D23),
    ink: Color(0xFFF4F6F1),
    inkSoft: Color(0xFF9EABA2),
    line: Color(0xFF293A30),
    forest: Color(0xFF2A5C43),
    forestDeep: Color(0xFF101E16),
    lime: Color(0xFFC7F36B),
    limeSoft: Color(0xFF26371D),
    gold: Color(0xFFF1C75B),
    goldSoft: Color(0xFF352E1A),
    coral: Color(0xFFFF8A74),
    coralSoft: Color(0xFF3A211D),
    skySoft: Color(0xFF1D2D29),
    shadow: Color(0x66000000),
  );

  @override
  TakaPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? ink,
    Color? inkSoft,
    Color? line,
    Color? forest,
    Color? forestDeep,
    Color? lime,
    Color? limeSoft,
    Color? gold,
    Color? goldSoft,
    Color? coral,
    Color? coralSoft,
    Color? skySoft,
    Color? shadow,
  }) {
    return TakaPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      line: line ?? this.line,
      forest: forest ?? this.forest,
      forestDeep: forestDeep ?? this.forestDeep,
      lime: lime ?? this.lime,
      limeSoft: limeSoft ?? this.limeSoft,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      coral: coral ?? this.coral,
      coralSoft: coralSoft ?? this.coralSoft,
      skySoft: skySoft ?? this.skySoft,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  TakaPalette lerp(covariant ThemeExtension<TakaPalette>? other, double t) {
    if (other is! TakaPalette) return this;
    return TakaPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      line: Color.lerp(line, other.line, t)!,
      forest: Color.lerp(forest, other.forest, t)!,
      forestDeep: Color.lerp(forestDeep, other.forestDeep, t)!,
      lime: Color.lerp(lime, other.lime, t)!,
      limeSoft: Color.lerp(limeSoft, other.limeSoft, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      coralSoft: Color.lerp(coralSoft, other.coralSoft, t)!,
      skySoft: Color.lerp(skySoft, other.skySoft, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(TakaPalette.light, Brightness.light);

  static ThemeData dark() => _build(TakaPalette.dark, Brightness.dark);

  static ThemeData _build(TakaPalette palette, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Manrope',
      scaffoldBackgroundColor: palette.background,
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = _textTheme(palette);

    final scheme = ColorScheme.fromSeed(
      seedColor: palette.forest,
      brightness: brightness,
      primary: palette.forest,
      secondary: palette.lime,
      surface: palette.surface,
      error: palette.coral,
    ).copyWith(
      onPrimary: isDark ? palette.ink : Colors.white,
      onSecondary: palette.forestDeep,
      onSurface: palette.ink,
      onSurfaceVariant: palette.inkSoft,
      outline: palette.line,
      outlineVariant: palette.line,
      surfaceContainerHighest: palette.surfaceMuted,
    );

    return base.copyWith(
      colorScheme: scheme,
      textTheme: textTheme,
      primaryColor: palette.forest,
      extensions: [palette],
      visualDensity: VisualDensity.standard,
      splashColor: palette.lime.withValues(alpha: 0.16),
      highlightColor: palette.lime.withValues(alpha: 0.08),
      dividerColor: palette.line,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: palette.ink, size: 22),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: palette.ink),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      iconTheme: IconThemeData(color: palette.ink, size: 22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceMuted,
        hintStyle: textTheme.bodyLarge?.copyWith(color: palette.inkSoft),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.inkSoft),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.forest, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.coral, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.coral, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.forest,
          foregroundColor: isDark ? palette.ink : Colors.white,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          side: BorderSide(color: palette.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.ink,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.surface,
        modalBarrierColor: palette.forestDeep.withValues(alpha: 0.48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: palette.ink),
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: palette.inkSoft,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.forestDeep,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.forestDeep
              : palette.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.lime
              : palette.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : palette.line,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(1),
      ),
      dividerTheme: DividerThemeData(
        color: palette.line,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.forest,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: palette.forest,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStatePropertyAll(palette.ink),
        todayForegroundColor: WidgetStatePropertyAll(palette.forest),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: textTheme.bodyMedium,
      ),
    );
  }

  static TextTheme _textTheme(TakaPalette p) {
    TextStyle style({
      required double size,
      FontWeight weight = FontWeight.w500,
      double height = 1.35,
      double letterSpacing = 0,
      Color? color,
    }) {
      return TextStyle(
        fontFamily: 'Manrope',
        fontFamilyFallback: const ['NotoSansBengali'],
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? p.ink,
      );
    }

    return TextTheme(
      displayLarge: style(
        size: 44,
        weight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.8,
      ),
      displayMedium: style(
        size: 38,
        weight: FontWeight.w800,
        height: 1.08,
        letterSpacing: -1.4,
      ),
      displaySmall: style(
        size: 32,
        weight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -1,
      ),
      headlineLarge: style(
        size: 30,
        weight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.9,
      ),
      headlineMedium: style(
        size: 26,
        weight: FontWeight.w800,
        height: 1.18,
        letterSpacing: -0.7,
      ),
      headlineSmall: style(
        size: 22,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.4,
      ),
      titleLarge: style(
        size: 19,
        weight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.2,
      ),
      titleMedium: style(
        size: 16,
        weight: FontWeight.w700,
        height: 1.3,
      ),
      titleSmall: style(
        size: 14,
        weight: FontWeight.w700,
        height: 1.3,
      ),
      bodyLarge: style(
        size: 15,
        weight: FontWeight.w500,
        height: 1.55,
      ),
      bodyMedium: style(
        size: 13.5,
        weight: FontWeight.w500,
        height: 1.5,
      ),
      bodySmall: style(
        size: 12,
        weight: FontWeight.w500,
        height: 1.45,
      ),
      labelLarge: style(
        size: 14,
        weight: FontWeight.w700,
        height: 1.25,
      ),
      labelMedium: style(
        size: 12,
        weight: FontWeight.w700,
        height: 1.25,
        letterSpacing: 0.2,
      ),
      labelSmall: style(
        size: 10.5,
        weight: FontWeight.w700,
        height: 1.25,
        letterSpacing: 1.1,
        color: p.inkSoft,
      ),
    );
  }
}

extension TakaContext on BuildContext {
  TakaPalette get taka => Theme.of(this).extension<TakaPalette>()!;

  TextTheme get texts => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
