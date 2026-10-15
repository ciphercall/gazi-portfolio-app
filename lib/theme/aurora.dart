import 'package:flutter/material.dart';

/// Midnight Aurora, in Dart.
///
/// Deliberately mirrors `gazi-portfolio/src/app/globals.css`: the same canvas,
/// the same accent triple, the same radii and the same type voices. The web app
/// and this app are meant to read as one product, so a colour changed in one
/// place should be changed in the other.
///
/// Weights are applied with `FontVariation` because both families are variable
/// fonts registered once per family in pubspec.yaml.
class Aurora {
  Aurora._();

  // ---------------------------------------------------------------- canvas --
  static const canvas = Color(0xFF060910);
  static const canvas2 = Color(0xFF0B1220);
  static const ink = Color(0xFFF8FAFC);
  static const muted = Color(0xFF94A3B8);
  static const faint = Color(0xFF64748B);

  static const line = Color(0x14FFFFFF);
  static const lineStrong = Color(0x29FFFFFF);
  static const panel = Color(0x0AFFFFFF);
  static const panelStrong = Color(0x12FFFFFF);

  // ---------------------------------------------------------------- accents --
  static const teal = Color(0xFF17C7B7);
  static const cyan = Color(0xFF2AD6FF);
  static const violet = Color(0xFFA37EE1);
  static const rose = Color(0xFFFF7AB6);

  static const onAccent = Color(0xFF04121A);

  /// The signature sweep. Every gradient in the app comes from this list so the
  /// product has exactly one accent language.
  static const sweep = <Color>[teal, cyan, violet];

  static const sweepReverse = <Color>[violet, cyan, teal];

  // ------------------------------------------------------------------ shape --
  static const radiusCard = 20.0;
  static const radiusControl = 12.0;
  static const radiusPill = 999.0;

  // ----------------------------------------------------------------- motion --
  static const easeAurora = Cubic(0.22, 1, 0.36, 1);
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 620);

  // ------------------------------------------------------------------- type --
  static TextStyle display(double size, {double weight = 600, Color color = ink}) {
    return TextStyle(
      fontFamily: 'Sora',
      fontSize: size,
      height: 1.06,
      letterSpacing: -size * 0.030,
      color: color,
      fontVariations: [FontVariation('wght', weight)],
    );
  }

  static TextStyle body(double size, {double weight = 400, Color color = ink}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      height: 1.62,
      letterSpacing: 0,
      color: color,
      fontVariations: [FontVariation('wght', weight)],
    );
  }

  /// Small uppercase label. Used for section eyebrows so structure is legible
  /// without relying on colour.
  static TextStyle label({Color color = faint}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: 11,
      height: 1.3,
      letterSpacing: 1.6,
      color: color,
      fontVariations: const [FontVariation('wght', 600)],
    );
  }

  // ---------------------------------------------------------------- surface --
  static BoxDecoration glass({double radius = radiusCard}) {
    return BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: line, width: 1),
    );
  }

  static BoxDecoration glassStrong({double radius = radiusCard}) {
    return BoxDecoration(
      color: panelStrong,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: lineStrong, width: 1),
    );
  }

  static LinearGradient gradient({List<Color>? colors, double angle = 100}) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors ?? sweep,
    );
  }
}

ThemeData buildAuroraTheme() {
  const scheme = ColorScheme.dark(
    primary: Aurora.teal,
    onPrimary: Aurora.onAccent,
    secondary: Aurora.cyan,
    onSecondary: Aurora.onAccent,
    tertiary: Aurora.violet,
    surface: Aurora.canvas,
    onSurface: Aurora.ink,
    error: Aurora.rose,
    onError: Aurora.onAccent,
    outline: Aurora.lineStrong,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Aurora.canvas,
    canvasColor: Aurora.canvas,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Aurora.ink,
      displayColor: Aurora.ink,
      fontFamily: 'Inter',
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    dividerTheme: const DividerThemeData(color: Aurora.line, thickness: 1, space: 1),
    // Touch feedback that reads on a dark glass surface.
    splashColor: Aurora.teal.withValues(alpha: 0.10),
    highlightColor: Aurora.teal.withValues(alpha: 0.06),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
