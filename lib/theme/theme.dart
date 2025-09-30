import 'package:flutter/material.dart';

/// ----- Brand ThemeExtension -----
@immutable
class AppBrand extends ThemeExtension<AppBrand> {
  final Color brand; // Connectly Yellow
  final Color brandDark; // darker brand shade (hover / pressed)
  final Color ink; // near-black
  final Color slate; // dark gray
  final Color graphite; // mid gray
  final Color softGrey; // light border grey
  final Color surfaceAlt; // subtle alternative surface (cards / chips)
  final Color surfaceElevated; // elevated surface color
  final Color accentPurple; // accent highlight (calls, featured blocks)
  final Color success; // success / positive state
  final Color warning; // warning / caution state
  final Color danger; // error / destructive
  final Color info; // informational accent
  final Color overlay; // scrims / modal backgrounds
  final Gradient heroGradient;
  final double radius; // global corner radius
  final List<BoxShadow> softShadow;

  const AppBrand({
    required this.brand,
    required this.brandDark,
    required this.ink,
    required this.slate,
    required this.graphite,
    required this.softGrey,
    required this.surfaceAlt,
    required this.surfaceElevated,
    required this.accentPurple,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.overlay,
    required this.heroGradient,
    required this.radius,
    required this.softShadow,
  });

  @override
  AppBrand copyWith({
    Color? brand,
    Color? brandDark,
    Color? ink,
    Color? slate,
    Color? graphite,
    Color? softGrey,
    Color? surfaceAlt,
    Color? surfaceElevated,
    Color? accentPurple,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? overlay,
    Gradient? heroGradient,
    double? radius,
    List<BoxShadow>? softShadow,
  }) {
    return AppBrand(
      brand: brand ?? this.brand,
      brandDark: brandDark ?? this.brandDark,
      ink: ink ?? this.ink,
      slate: slate ?? this.slate,
      graphite: graphite ?? this.graphite,
      softGrey: softGrey ?? this.softGrey,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      accentPurple: accentPurple ?? this.accentPurple,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      overlay: overlay ?? this.overlay,
      heroGradient: heroGradient ?? this.heroGradient,
      radius: radius ?? this.radius,
      softShadow: softShadow ?? this.softShadow,
    );
  }

  @override
  AppBrand lerp(ThemeExtension<AppBrand>? other, double t) {
    if (other is! AppBrand) return this;
    return AppBrand(
      brand: Color.lerp(brand, other.brand, t)!,
      brandDark: Color.lerp(brandDark, other.brandDark, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      slate: Color.lerp(slate, other.slate, t)!,
      graphite: Color.lerp(graphite, other.graphite, t)!,
      softGrey: Color.lerp(softGrey, other.softGrey, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      heroGradient: LinearGradient.lerp(
        heroGradient as LinearGradient?,
        other.heroGradient as LinearGradient?,
        t,
      )!,
      radius: lerpDouble(radius, other.radius, t),
      softShadow: _lerpShadows(softShadow, other.softShadow, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  static List<BoxShadow> _lerpShadows(
    List<BoxShadow> a,
    List<BoxShadow> b,
    double t,
  ) {
    final maxLen = (a.length > b.length) ? a.length : b.length;
    return List<BoxShadow>.generate(maxLen, (i) {
      final sa = (i < a.length) ? a[i] : const BoxShadow();
      final sb = (i < b.length) ? b[i] : const BoxShadow();
      return BoxShadow(
        color: Color.lerp(sa.color, sb.color, t) ?? Colors.black,
        blurRadius: lerpDouble(sa.blurRadius, sb.blurRadius, t),
        spreadRadius: lerpDouble(sa.spreadRadius, sb.spreadRadius, t),
        offset: Offset(
          lerpDouble(sa.offset.dx, sb.offset.dx, t),
          lerpDouble(sa.offset.dy, sb.offset.dy, t),
        ),
      );
    });
  }
}

/// ----- Light & Dark ThemeData -----
class ConnectlyTheme {
  // Brand constants
  static const _brand = Color(0xFFF5B400);
  static const _brandDark = Color(0xFFD79A00);
  static const _ink = Color(0xFF0F0F12);
  static const _slate = Color(0xFF1A1B1E);
  static const _graphite = Color(0xFF2A2C31);
  static const _softGrey = Color(0xFFE6E8EE);
  static const _white = Color(0xFFFFFFFF);
  // New semantic colors (derived / complementary)
  static const _accentPurple = Color(0xFFA78BFA); // used in upcoming call card
  static const _success = Color(0xFF2E7D32);
  static const _warning = Color(0xFFEDB200);
  static const _danger = Color(0xFFE53935);
  static const _info = Color(0xFF2F80ED);
  static const _surfaceAltLight = Color(
    0xFFF8F9FA,
  ); // improved alt surface for devices
  static const _surfaceElevatedLight = Color(0xFFFFFFFF);
  static const _overlayLight = Color(0x990F0F12); // semi-transparent ink

  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _brand,
      onPrimary: _ink,
      secondary: _graphite,
      onSecondary: _white,
      surface: _white,
      onSurface: _ink,
      background: const Color(0xFFFAFBFD),
      onBackground: _ink,
      error: const Color(0xFFB00020),
      onError: _white,
      tertiary: _slate,
      onTertiary: _white,
      surfaceContainerHighest: _softGrey,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      textTheme: _textTheme(colorScheme.onSurface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _white,
        border: _outline(),
        enabledBorder: _outline(),
        focusedBorder: _outline(color: _brand),
        hintStyle: TextStyle(color: _graphite.withOpacity(0.55)),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _softGrey.withOpacity(0.8), width: 1),
        ),
      ),
      buttonTheme: const ButtonThemeData(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brand,
          foregroundColor: _ink,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      extensions: [
        AppBrand(
          brand: _brand,
          brandDark: _brandDark,
          ink: _ink,
          slate: _slate,
          graphite: _graphite,
          softGrey: _softGrey,
          surfaceAlt: _surfaceAltLight,
          surfaceElevated: _surfaceElevatedLight,
          accentPurple: _accentPurple,
          success: _success,
          warning: _warning,
          danger: _danger,
          info: _info,
          overlay: _overlayLight,
          radius: 16,
          heroGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD766), // lighter yellow highlight
              _brand,
            ],
          ),
          softShadow: [
            BoxShadow(
              color: _ink.withOpacity(0.06),
              blurRadius: 22,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ],
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _brand,
      onPrimary: _ink,
      secondary: _brand.withOpacity(0.85),
      onSecondary: _ink,
      surface: _slate,
      onSurface: _white,
      background: _ink,
      onBackground: _white,
      error: const Color(0xFFFF4D4D),
      onError: _ink,
      tertiary: _graphite,
      onTertiary: _white,
      surfaceContainerHighest: _graphite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      textTheme: _textTheme(colorScheme.onSurface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _graphite,
        border: _outline(color: _graphite),
        enabledBorder: _outline(color: _graphite),
        focusedBorder: _outline(color: _brand),
        hintStyle: TextStyle(color: _white.withOpacity(0.6)),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _graphite.withOpacity(0.6), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brand,
          foregroundColor: _ink,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      extensions: [
        AppBrand(
          brand: _brand,
          brandDark: _brandDark,
          ink: _ink,
          slate: _slate,
          graphite: _graphite,
          softGrey: _softGrey,
          surfaceAlt: _graphite, // darker alt in dark mode
          surfaceElevated: _slate,
          accentPurple: _accentPurple,
          success: _success,
          warning: _warning,
          danger: _danger,
          info: _info,
          overlay: Colors.black.withOpacity(0.55),
          radius: 16,
          heroGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_brand, const Color(0xFFFFC533)],
          ),
          softShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 12),
            ),
          ],
        ),
      ],
    );
  }

  static OutlineInputBorder _outline({Color color = _softGrey}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: 1),
    );
  }

  static TextTheme _textTheme(Color baseColor) {
    return Typography.englishLike2018
        .apply(bodyColor: baseColor, displayColor: baseColor)
        .copyWith(
          displayLarge: TextStyle(fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(height: 1.35),
          bodyMedium: TextStyle(height: 1.35),
          labelLarge: TextStyle(fontWeight: FontWeight.w600),
        );
  }
}
