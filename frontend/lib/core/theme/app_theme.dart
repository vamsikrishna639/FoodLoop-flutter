// Builds the two ThemeData objects: "paper" (light) and "chalkboard" (dark).
// This is the only file in the app that contains raw hex colours.
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData get paper => _build(_paperColors, Brightness.light);
  static ThemeData get chalkboard => _build(_chalkColors, Brightness.dark);

  // ---- Raw palette -------------------------------------------------------

  static const _paperColors = _Palette(
    paper: Color(0xFFF6F1E7),
    surface: Color(0xFFFBF8F2),
    surfaceSunken: Color(0xFFEFE8DA),
    ink: Color(0xFF1E1B16),
    inkSoft: Color(0xFF6B6255),
    line: Color(0xFFE3DACB),
    perforation: Color(0xFFCFC4B2),
    controlBorder: Color(0xFF8C8272),
    chilli: Color(0xFFD9472B),
    chilliDeep: Color(0xFFB93A21),
    onChilli: Color(0xFFFBF8F2),
    leaf: Color(0xFF2F6B3F),
    onLeaf: Color(0xFFFBF8F2),
    turmeric: Color(0xFFE8A33D),
    turmericDeep: Color(0xFF8A5A0B),
    stampGrey: Color(0xFF6B6255),
  );

  static const _chalkColors = _Palette(
    paper: Color(0xFF1F2422),
    surface: Color(0xFF272D2A),
    surfaceSunken: Color(0xFF1A1F1D),
    ink: Color(0xFFECE8DF),
    inkSoft: Color(0xFFA9A397),
    line: Color(0xFF3A423E),
    perforation: Color(0xFF4B544F),
    controlBorder: Color(0xFF7C857F),
    chilli: Color(0xFFF0674B),
    chilliDeep: Color(0xFFF0674B),
    onChilli: Color(0xFF1E1B16),
    leaf: Color(0xFF6FBF83),
    onLeaf: Color(0xFF1E1B16),
    turmeric: Color(0xFFF2B65A),
    turmericDeep: Color(0xFFF2B65A),
    stampGrey: Color(0xFF8E958F),
  );

  // The chalkboard block looks the same in both themes.
  static const _board = Color(0xFF232927);
  static const _boardFrame = Color(0xFF3A2E22);
  static const _chalk = Color(0xFFECE8DF);
  static const _chalkSoft = Color(0xFFA9A397);
  static const _chalkLine = Color(0xFF3A423E);
  static const _onTurmeric = Color(0xFF1E1B16);

  // ---- Fonts -------------------------------------------------------------

  static TextStyle _display(double size, FontWeight w, double height, double tracking, Color c) =>
      GoogleFonts.bricolageGrotesque(
          fontSize: size, fontWeight: w, height: height, letterSpacing: tracking, color: c);

  static TextStyle _body(double size, FontWeight w, double height, double tracking, Color c) =>
      GoogleFonts.instrumentSans(
          fontSize: size, fontWeight: w, height: height, letterSpacing: tracking, color: c);

  // Tabular figures keep digits the same width, so countdowns do not jiggle.
  static TextStyle _mono(double size, FontWeight w, double height, double tracking, Color c) =>
      GoogleFonts.jetBrainsMono(
          fontSize: size,
          fontWeight: w,
          height: height,
          letterSpacing: tracking,
          color: c,
          fontFeatures: const [FontFeature.tabularFigures()]);

  // ---- Theme -------------------------------------------------------------

  static ThemeData _build(_Palette p, Brightness brightness) {
    final textTheme = TextTheme(
      displayLarge: _display(56, FontWeight.w800, 1.0, -1.5, p.ink),
      displayMedium: _display(44, FontWeight.w700, 1.05, -1.0, p.ink),
      displaySmall: _display(36, FontWeight.w700, 1.1, -0.8, p.ink),
      headlineMedium: _display(28, FontWeight.w700, 1.15, -0.5, p.ink),
      headlineSmall: _display(22, FontWeight.w700, 1.2, -0.3, p.ink),
      titleLarge: _display(19, FontWeight.w600, 1.25, -0.2, p.ink),
      titleMedium: _body(16, FontWeight.w600, 1.35, 0, p.ink),
      titleSmall: _body(14, FontWeight.w600, 1.35, 0.1, p.ink),
      bodyLarge: _body(16, FontWeight.w400, 1.5, 0, p.ink),
      bodyMedium: _body(14, FontWeight.w400, 1.5, 0, p.ink),
      bodySmall: _body(12.5, FontWeight.w400, 1.45, 0.1, p.inkSoft),
      labelLarge: _body(15, FontWeight.w600, 1.2, 0.1, p.ink),
      labelMedium: _body(13, FontWeight.w600, 1.2, 0.2, p.ink),
      labelSmall: _body(12.5, FontWeight.w600, 1.2, 0.3, p.inkSoft),
    );

    final tokens = FoodLoopTokens(
      paper: p.paper,
      surface: p.surface,
      surfaceSunken: p.surfaceSunken,
      ink: p.ink,
      inkSoft: p.inkSoft,
      line: p.line,
      perforation: p.perforation,
      controlBorder: p.controlBorder,
      chilli: p.chilli,
      chilliDeep: p.chilliDeep,
      onChilli: p.onChilli,
      leaf: p.leaf,
      onLeaf: p.onLeaf,
      turmeric: p.turmeric,
      turmericDeep: p.turmericDeep,
      onTurmeric: _onTurmeric,
      stampGrey: p.stampGrey,
      board: _board,
      boardFrame: _boardFrame,
      chalk: _chalk,
      chalkSoft: _chalkSoft,
      chalkLine: _chalkLine,
      impact: _display(72, FontWeight.w800, 0.95, -2.0, p.ink),
      monoLarge: _mono(18, FontWeight.w700, 1.3, 0, p.ink),
      mono: _mono(13.5, FontWeight.w500, 1.4, 0, p.ink),
      monoSmall: _mono(11.5, FontWeight.w500, 1.3, 0.6, p.inkSoft),
      stamp: _mono(12, FontWeight.w800, 1.0, 1.6, p.ink),
    );

    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.chilliDeep,
      onPrimary: p.onChilli,
      secondary: p.leaf,
      onSecondary: p.onLeaf,
      tertiary: p.turmeric,
      onTertiary: _onTurmeric,
      error: p.chilliDeep,
      onError: p.onChilli,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.inkSoft,
      outline: p.controlBorder,
      outlineVariant: p.line,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceSunken,
      surfaceContainerHighest: p.surfaceSunken,
      inverseSurface: p.ink,
      onInverseSurface: p.paper,
      shadow: const Color(0xFF1E1B16),
      scrim: const Color(0xFF1E1B16),
    );

    final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(FlRadius.control));
    OutlineInputBorder inputBorder(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(FlRadius.control),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.paper,
      canvasColor: p.paper,
      textTheme: textTheme,
      extensions: [tokens],
      splashFactory: NoSplash.splashFactory, // paper does not ripple
      highlightColor: p.ink.withValues(alpha: 0.06),
      hoverColor: p.ink.withValues(alpha: 0.04),
      focusColor: p.ink.withValues(alpha: 0.08),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: p.ink, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: p.paper,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      // Default filled button = ink on paper. The chilli accent button is
      // FlButton(variant: accent) so it stays rare.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.paper,
          // Disabled = an empty paper slot with soft ink text and an outline,
          // not a faded version of the colour (a pale fill with white text
          // is hard to read and looks broken rather than "not yet").
          disabledBackgroundColor: p.surfaceSunken,
          disabledForegroundColor: p.inkSoft,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: FlSpace.xl),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ).copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? BorderSide(color: p.controlBorder) : null,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: FlSpace.xl),
          side: BorderSide(color: p.ink, width: 1.5),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.ink,
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.ink, minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceSunken,
        contentPadding: const EdgeInsets.symmetric(horizontal: FlSpace.lg, vertical: 14),
        hintStyle: textTheme.bodyLarge?.copyWith(color: p.inkSoft),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: p.chilliDeep, fontWeight: FontWeight.w600),
        errorMaxLines: 2,
        border: inputBorder(p.controlBorder),
        enabledBorder: inputBorder(p.controlBorder),
        focusedBorder: inputBorder(p.ink, 2),
        errorBorder: inputBorder(p.chilliDeep, 1.5),
        focusedErrorBorder: inputBorder(p.chilliDeep, 2),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FlRadius.sheet)),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.perforation,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(FlRadius.sheet)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(FlRadius.stamp)),
        textStyle: textTheme.bodySmall?.copyWith(color: p.paper),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.paper : p.inkSoft),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.ink : p.surfaceSunken),
        trackOutlineColor: WidgetStatePropertyAll(p.controlBorder),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
    );
  }
}

/// Internal holder for one theme's raw colours.
class _Palette {
  const _Palette({
    required this.paper,
    required this.surface,
    required this.surfaceSunken,
    required this.ink,
    required this.inkSoft,
    required this.line,
    required this.perforation,
    required this.controlBorder,
    required this.chilli,
    required this.chilliDeep,
    required this.onChilli,
    required this.leaf,
    required this.onLeaf,
    required this.turmeric,
    required this.turmericDeep,
    required this.stampGrey,
  });

  final Color paper, surface, surfaceSunken, ink, inkSoft, line, perforation, controlBorder;
  final Color chilli, chilliDeep, onChilli, leaf, onLeaf, turmeric, turmericDeep, stampGrey;
}
