import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/aurora.dart';
import 'background_field.dart';

const List<Color> _accents = [Aurora.teal, Aurora.cyan, Aurora.violet, Aurora.rose];

/// The living background behind every screen.
///
/// Eight industry outlines — database, document, monitor, phone, cloud, shield,
/// chip, code — drift and morph into each other continuously, with no fill and
/// only colourful outlines. When a shape settles, the real Lucide SVG bundled
/// under `assets/icons/field` resolves in its place. A tap sends a pulse
/// through the field and pulls the nearest shapes toward the touch point. It is
/// the app's one always-on animation, so it stays a single `CustomPaint` on a
/// long cycle; reduced-motion users get one static frame.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, this.intensity = 1.0, this.child});

  final double intensity;
  final Widget? child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  final List<_Pulse> _pulses = [];
  bool _reduceMotion = false;
  List<ui.Picture?> _icons = const [];

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  /// Loads the vendored Lucide SVGs once, tinted with each element's accent.
  Future<void> _loadIcons() async {
    final pictures = <ui.Picture?>[];
    for (var index = 0; index < kIconAssets.length; index++) {
      final tone = kIconTones[index % kIconTones.length];
      final colour = _accents[tone[0] % _accents.length];
      try {
        final info = await vg.loadPicture(
          SvgAssetLoader(kIconAssets[index], theme: SvgTheme(currentColor: colour)),
          null,
        );
        pictures.add(info.picture);
      } catch (_) {
        pictures.add(null);
      }
    }

    if (!mounted) return;
    setState(() => _icons = pictures);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce == _reduceMotion) return;

    _reduceMotion = reduce;
    if (reduce) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pulseAt(Offset position) {
    if (_reduceMotion) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    _pulses.removeWhere((pulse) => now - pulse.startedMs > kRippleMs);
    _pulses.add(_Pulse(position, now));
    if (_pulses.length > 5) _pulses.removeAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _pulseAt(event.localPosition),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Aurora.canvas),
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _FieldPainter(
                      elapsedMs: _reduceMotion ? 0 : _controller.value * 26000,
                      nowMs: DateTime.now().millisecondsSinceEpoch,
                      pulses: List.of(_pulses),
                      intensity: widget.intensity,
                      icons: _icons,
                    ),
                  ),
                ),
              ),
            ),
            // The field is a backdrop: this veil keeps the content dominant even
            // before the frosted panels are drawn over it.
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: Aurora.canvas.withValues(alpha: 0.42)),
              ),
            ),
            if (widget.child != null) Positioned.fill(child: widget.child!),
          ],
        ),
      ),
    );
  }
}

class _Pulse {
  const _Pulse(this.position, this.startedMs);

  final Offset position;
  final int startedMs;
}

class _FieldPainter extends CustomPainter {
  _FieldPainter({
    required this.elapsedMs,
    required this.nowMs,
    required this.pulses,
    required this.intensity,
    required this.icons,
  });

  final double elapsedMs;
  final int nowMs;
  final List<_Pulse> pulses;
  final double intensity;
  final List<ui.Picture?> icons;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;

    Offset? pointer;
    var strength = 0.0;
    if (pulses.isNotEmpty) {
      final age = (nowMs - pulses.last.startedMs).toDouble();
      final fade = (1 - age / 1500).clamp(0.0, 1.0);
      if (fade > 0) {
        pointer = pulses.last.position;
        strength = shortest * 0.022 * fade;
      }
    }

    _paintGrid(canvas, size);

    for (var index = 0; index < kFieldGlyphs.length; index++) {
      final glyph = kFieldGlyphs[index];
      final transform = glyphTransform(glyph, elapsedMs, size.width, size.height);
      final state = morphState(elapsedMs, glyph.phase, glyph.shapeOffset);
      final ring = blendedRing(
        kShapeRings[state.from],
        kShapeRings[state.to],
        state.t,
        0.004,
        elapsedMs,
      );

      final cosR = math.cos(transform.rotation);
      final sinR = math.sin(transform.rotation);
      final placed = [
        for (final point in ring)
          Offset(
            transform.cx + (point.dx * cosR - point.dy * sinR) * transform.size,
            transform.cy + (point.dx * sinR + point.dy * cosR) * transform.size,
          ),
      ];

      final points = applyPointerInfluence(
        placed,
        pointer,
        shortest * 0.34,
        strength,
      );

      final accent = _accents[(index + state.from) % _accents.length];
      final second = _accents[(index + state.from + 1) % _accents.length];
      final centre = Offset(transform.cx, transform.cy);

      // A shape near the touch lights up, so a tap visibly stirs the field and
      // not only the geometry.
      final proximity = pointer == null
          ? 0.0
          : math.max(0.0, 1 - (centre - pointer).distance / (shortest * 0.65));

      // Outline only: no fills anywhere in the field.
      final path = _smoothPath(points);
      final bounds = Rect.fromCenter(
        center: centre,
        width: transform.size,
        height: transform.size,
      );
      final outline = intensity * (1 + proximity * 1.3);

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 1.4 + proximity * 1.2
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.30 * outline),
              second.withValues(alpha: 0.24 * outline),
            ],
          ).createShader(bounds),
      );

      // Settled: the real downloaded SVG outline resolves in place, then fades
      // away as the next morph starts.
      final settle = iconAlpha(elapsedMs, glyph.phase);
      if (settle > 0.01) {
        final iconIndex = iconShapeIndex(state);
        final picture = icons.isEmpty ? null : icons[iconIndex % icons.length];
        if (picture != null) {
          final iconSize = transform.size * 0.86;
          canvas.save();
          canvas.translate(centre.dx, centre.dy);
          canvas.rotate(transform.rotation);
          canvas.scale(iconSize / 24);
          canvas.translate(-12, -12);
          canvas.saveLayer(
            const Rect.fromLTWH(0, 0, 24, 24),
            Paint()..color = Colors.white.withValues(alpha: settle * 0.82),
          );
          canvas.drawPicture(picture);
          canvas.restore();
          canvas.restore();
        }
      }
    }

    for (final pulse in pulses) {
      final progress = rippleProgress((nowMs - pulse.startedMs).toDouble());
      if (progress >= 1) continue;

      final radius = 18 + progress * shortest * 0.52;
      canvas.drawCircle(
        pulse.position,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Aurora.teal.withValues(alpha: (1 - progress) * 0.28),
      );
      canvas.drawCircle(
        pulse.position,
        radius * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Aurora.violet.withValues(alpha: (1 - progress) * 0.16),
      );
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Aurora.ink.withValues(alpha: 0.028)
      ..strokeWidth = 1;
    const step = 56.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    final start = Offset(
      (points.last.dx + points.first.dx) / 2,
      (points.last.dy + points.first.dy) / 2,
    );
    path.moveTo(start.dx, start.dy);

    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final mid = Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_FieldPainter oldDelegate) {
    return oldDelegate.elapsedMs != elapsedMs ||
        oldDelegate.pulses.length != pulses.length ||
        oldDelegate.intensity != intensity ||
        oldDelegate.icons != icons;
  }
}

/// Gradient-filled text. Used for the name and section keywords, so the accent
/// language appears in type and not only in decoration.
class AuroraText extends StatelessWidget {
  const AuroraText(this.text, {super.key, required this.style, this.colors});

  final String text;
  final TextStyle style;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => Aurora.gradient(colors: colors).createShader(bounds),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
