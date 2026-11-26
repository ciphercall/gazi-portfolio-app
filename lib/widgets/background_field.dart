import 'dart:math' as math;
import 'dart:ui';

/// Motion maths for the living background.
///
/// Eight industry silhouettes (database, document, monitor, phone, cloud,
/// shield, chip, code) are resampled to equal-length rings so one can morph
/// into the next. This mirrors `src/lib/background/field.ts` in the web app;
/// keep the two in step.
///
/// Everything here is pure so the painter stays a thin adapter.

const int kRingPoints = 48;
const int kHoldMs = 11000;
const int kMorphMs = 3000;
const int kCycleMs = kHoldMs + kMorphMs;
const int kRippleMs = 1200;

double easeInOutCubic(double t) {
  final clamped = t.clamp(0.0, 1.0);
  if (clamped < 0.5) return 4 * clamped * clamped * clamped;
  return 1 - math.pow(-2 * clamped + 2, 3) / 2;
}

List<Offset> _database() {
  final points = <Offset>[];
  const cx = 0.5;
  const rx = 0.32;
  const ry = 0.1;
  const top = 0.26;
  const bottom = 0.74;

  for (var i = 0; i <= 10; i++) {
    final angle = math.pi - (math.pi * i) / 10;
    points.add(Offset(cx + rx * math.cos(angle), top - ry * math.sin(angle)));
  }
  points.add(const Offset(cx + rx, bottom));
  for (var i = 0; i <= 10; i++) {
    final angle = (math.pi * i) / 10;
    points.add(Offset(cx + rx * math.cos(angle), bottom + ry * math.sin(angle)));
  }
  return points;
}

List<Offset> _document() => const [
      Offset(0.22, 0.12),
      Offset(0.64, 0.12),
      Offset(0.66, 0.14),
      Offset(0.66, 0.3),
      Offset(0.8, 0.3),
      Offset(0.8, 0.88),
      Offset(0.22, 0.88),
    ];

List<Offset> _monitor() => const [
      Offset(0.1, 0.18),
      Offset(0.9, 0.18),
      Offset(0.9, 0.64),
      Offset(0.58, 0.64),
      Offset(0.58, 0.76),
      Offset(0.68, 0.76),
      Offset(0.68, 0.82),
      Offset(0.32, 0.82),
      Offset(0.32, 0.76),
      Offset(0.42, 0.76),
      Offset(0.42, 0.64),
      Offset(0.1, 0.64),
    ];

List<Offset> _phone() => const [
      Offset(0.32, 0.08),
      Offset(0.42, 0.08),
      Offset(0.42, 0.14),
      Offset(0.58, 0.14),
      Offset(0.58, 0.08),
      Offset(0.68, 0.08),
      Offset(0.72, 0.12),
      Offset(0.72, 0.88),
      Offset(0.68, 0.92),
      Offset(0.32, 0.92),
      Offset(0.28, 0.88),
      Offset(0.28, 0.12),
    ];

List<Offset> _cloud() {
  return List<Offset>.generate(20, (index) {
    final angle = (index / 20) * math.pi * 2;
    final radius = 0.34 + 0.055 * math.sin(3 * angle) + 0.03 * math.sin(5 * angle + 1.2);
    return Offset(
      0.5 + math.cos(angle) * radius * 1.3,
      0.54 + math.sin(angle) * radius * 0.82,
    );
  });
}

List<Offset> _shield() => const [
      Offset(0.5, 0.1),
      Offset(0.84, 0.22),
      Offset(0.8, 0.56),
      Offset(0.5, 0.9),
      Offset(0.2, 0.56),
      Offset(0.16, 0.22),
    ];

List<Offset> _chip() => const [
      Offset(0.3, 0.2),
      Offset(0.4, 0.2),
      Offset(0.4, 0.12),
      Offset(0.48, 0.12),
      Offset(0.48, 0.2),
      Offset(0.56, 0.2),
      Offset(0.56, 0.12),
      Offset(0.64, 0.12),
      Offset(0.64, 0.2),
      Offset(0.74, 0.2),
      Offset(0.74, 0.32),
      Offset(0.82, 0.32),
      Offset(0.82, 0.4),
      Offset(0.74, 0.4),
      Offset(0.74, 0.48),
      Offset(0.82, 0.48),
      Offset(0.82, 0.56),
      Offset(0.74, 0.56),
      Offset(0.74, 0.68),
      Offset(0.64, 0.68),
      Offset(0.64, 0.76),
      Offset(0.56, 0.76),
      Offset(0.56, 0.68),
      Offset(0.48, 0.68),
      Offset(0.48, 0.76),
      Offset(0.4, 0.76),
      Offset(0.4, 0.68),
      Offset(0.3, 0.68),
      Offset(0.3, 0.56),
      Offset(0.22, 0.56),
      Offset(0.22, 0.48),
      Offset(0.3, 0.48),
      Offset(0.3, 0.4),
      Offset(0.22, 0.4),
      Offset(0.22, 0.32),
      Offset(0.3, 0.32),
    ];

List<Offset> _code() => const [
      Offset(0.24, 0.2),
      Offset(0.38, 0.2),
      Offset(0.68, 0.5),
      Offset(0.38, 0.8),
      Offset(0.24, 0.8),
      Offset(0.54, 0.5),
    ];

List<Offset> _resamplePolygon(List<Offset> points, [int count = kRingPoints]) {
  final ring = [...points, points.first];
  final lengths = <double>[];
  var total = 0.0;

  for (var i = 0; i < ring.length - 1; i++) {
    final length = (ring[i + 1] - ring[i]).distance;
    lengths.add(length);
    total += length;
  }

  return List<Offset>.generate(count, (index) {
    var target = (total * index) / count;
    var segment = 0;
    while (segment < lengths.length - 1 && target > lengths[segment]) {
      target -= lengths[segment];
      segment++;
    }
    final t = lengths[segment] == 0 ? 0.0 : target / lengths[segment];
    return Offset.lerp(ring[segment], ring[segment + 1], t)!;
  });
}

List<Offset> _normaliseRing(List<Offset> ring) {
  var minX = double.infinity, maxX = -double.infinity;
  var minY = double.infinity, maxY = -double.infinity;

  for (final point in ring) {
    minX = math.min(minX, point.dx);
    maxX = math.max(maxX, point.dx);
    minY = math.min(minY, point.dy);
    maxY = math.max(maxY, point.dy);
  }

  final cx = (minX + maxX) / 2;
  final cy = (minY + maxY) / 2;
  final scale = math.max(maxX - minX, maxY - minY);

  return [for (final point in ring) Offset((point.dx - cx) / scale, (point.dy - cy) / scale)];
}

final List<List<Offset>> _rawShapes = [
  _database(),
  _document(),
  _monitor(),
  _phone(),
  _cloud(),
  _shield(),
  _chip(),
  _code(),
];

/// The eight silhouettes, ready to interpolate.
final List<List<Offset>> kShapeRings = _rawShapes
    .map((shape) => _normaliseRing(_resamplePolygon(shape)))
    .toList(growable: false);

/// Real Lucide outline assets bundled under `assets/icons/field` (ISC, see the
/// LICENSE there). The morph runs on [kShapeRings]; when a shape settles its
/// downloaded icon is drawn in place, mirroring the web app.
const List<String> kIconAssets = [
  'assets/icons/field/database.svg',
  'assets/icons/field/file-text.svg',
  'assets/icons/field/monitor.svg',
  'assets/icons/field/smartphone.svg',
  'assets/icons/field/cloud.svg',
  'assets/icons/field/shield.svg',
  'assets/icons/field/cpu.svg',
  'assets/icons/field/code-xml.svg',
];

/// Accent pairs (indices into the Aurora accent list) per element.
const List<List<int>> kIconTones = [
  [0, 1],
  [1, 2],
  [2, 0],
  [0, 3],
  [1, 2],
  [3, 0],
  [2, 1],
  [3, 1],
];

/// How visible the settled icon is: full while the shape rests, gone mid-morph,
/// cross-faded at both boundaries. Mirrors `iconAlpha` in the web app.
double iconAlpha(double elapsedMs, double phase) {
  final shifted = elapsedMs + phase * kCycleMs;
  final local = shifted % kCycleMs;
  if (local <= kHoldMs) return 1;

  final morph = local - kHoldMs;
  final fadeOut = kMorphMs * 0.18;
  final fadeInStart = kMorphMs * 0.72;

  if (morph <= fadeOut) return 1 - easeInOutCubic(morph / fadeOut);
  if (morph >= fadeInStart) {
    return easeInOutCubic((morph - fadeInStart) / (kMorphMs - fadeInStart));
  }
  return 0;
}

int iconShapeIndex(MorphState state) => state.t < 0.5 ? state.from : state.to;

class MorphState {
  const MorphState({required this.from, required this.to, required this.t});

  final int from;
  final int to;
  final double t;
}

MorphState morphState(double elapsedMs, double phase, double shapeOffset) {
  final shifted = elapsedMs + phase * kCycleMs;
  final index = (shifted / kCycleMs).floor() + (shapeOffset * kShapeRings.length).round();
  final local = shifted % kCycleMs;
  final t = local <= kHoldMs ? 0.0 : easeInOutCubic((local - kHoldMs) / kMorphMs);

  int wrap(int value) => ((value % kShapeRings.length) + kShapeRings.length) % kShapeRings.length;

  return MorphState(from: wrap(index), to: wrap(index + 1), t: t);
}

List<Offset> blendedRing(
  List<Offset> from,
  List<Offset> to,
  double t,
  double wobble,
  double timeMs,
) {
  final count = math.min(from.length, to.length);
  final result = <Offset>[];

  for (var i = 0; i < count; i++) {
    final angle = (i / count) * math.pi * 2;
    final wobbleX = math.sin(timeMs * 0.0006 + angle * 2.3) * wobble;
    final wobbleY = math.cos(timeMs * 0.0005 + angle * 1.7) * wobble;
    final base = Offset.lerp(from[i], to[i], t)!;
    result.add(Offset(base.dx + wobbleX, base.dy + wobbleY));
  }

  return result;
}

List<Offset> applyPointerInfluence(
  List<Offset> points,
  Offset? pointer,
  double radius,
  double strength,
) {
  if (pointer == null || strength <= 0 || radius <= 0) return points;

  return [
    for (final point in points)
      () {
        final delta = pointer - point;
        final distance = delta.distance;
        if (distance >= radius || distance == 0) return point;
        final falloff = math.pow(1 - distance / radius, 2).toDouble() * strength;
        return point + delta / distance * falloff;
      }(),
  ];
}

double rippleProgress(double ageMs, [double durationMs = 1200]) {
  return (ageMs / durationMs).clamp(0.0, 1.0);
}

class FieldGlyph {
  const FieldGlyph({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.driftX,
    required this.driftY,
    required this.spin,
    required this.shapeOffset,
  });

  final double x;
  final double y;
  final double size;
  final double phase;
  final double driftX;
  final double driftY;
  final double spin;
  final double shapeOffset;
}

const List<FieldGlyph> kFieldGlyphs = [
  FieldGlyph(x: 0.11, y: 0.2, size: 0.5, phase: 0.02, driftX: 0.016, driftY: 0.03, spin: 0.5, shapeOffset: 0),
  FieldGlyph(x: 0.84, y: 0.16, size: 0.42, phase: 0.37, driftX: 0.014, driftY: 0.024, spin: -0.4, shapeOffset: 0.35),
  FieldGlyph(x: 0.68, y: 0.62, size: 0.56, phase: 0.63, driftX: 0.02, driftY: 0.03, spin: 0.35, shapeOffset: 0.6),
  FieldGlyph(x: 0.18, y: 0.72, size: 0.44, phase: 0.18, driftX: 0.012, driftY: 0.022, spin: -0.55, shapeOffset: 0.15),
  FieldGlyph(x: 0.46, y: 0.38, size: 0.34, phase: 0.81, driftX: 0.018, driftY: 0.026, spin: 0.45, shapeOffset: 0.8),
  FieldGlyph(x: 0.93, y: 0.82, size: 0.38, phase: 0.51, driftX: 0.01, driftY: 0.018, spin: -0.3, shapeOffset: 0.5),
];

({double cx, double cy, double size, double rotation}) glyphTransform(
  FieldGlyph glyph,
  double elapsedMs,
  double width,
  double height,
) {
  final t = elapsedMs / 1000;
  final cx = (glyph.x + math.sin(t * 0.05 + glyph.phase * 6.28) * glyph.driftX) * width;
  final cy = (glyph.y + math.cos(t * 0.043 + glyph.phase * 5.1) * glyph.driftY) * height;
  final size = glyph.size * math.min(width, height);
  final rotation = math.sin(t * 0.035 + glyph.phase * 4.2) * glyph.spin;

  return (cx: cx, cy: cy, size: size, rotation: rotation);
}
