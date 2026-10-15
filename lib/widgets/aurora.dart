import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/aurora.dart';

/// The ambient aurora field behind a screen.
///
/// Three soft radial blooms in the accent triple over the ink canvas, drifting
/// slowly. It is the app's one piece of always-on motion, so it is deliberately
/// slow, low-contrast and cheap — a single `CustomPaint`, redrawn on a long
/// cycle, rather than a stack of blurred widgets.
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return DecoratedBox(
      decoration: const BoxDecoration(color: Aurora.canvas),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _AuroraPainter(
                    t: reduceMotion ? 0.35 : _controller.value,
                    intensity: widget.intensity,
                  ),
                ),
              ),
            ),
          ),
          if (widget.child != null) Positioned.fill(child: widget.child!),
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.t, required this.intensity});

  final double t;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = t * 2 * math.pi;

    void bloom(Offset centre, double radius, Color color, double opacity) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: opacity * intensity), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: centre, radius: radius));
      canvas.drawCircle(centre, radius, paint);
    }

    final r = size.shortestSide;

    bloom(
      Offset(
        size.width * (0.18 + 0.05 * math.sin(phase)),
        size.height * (0.16 + 0.04 * math.cos(phase * 0.8)),
      ),
      r * 0.75,
      Aurora.teal,
      0.20,
    );
    bloom(
      Offset(
        size.width * (0.86 + 0.04 * math.cos(phase * 0.7)),
        size.height * (0.10 + 0.05 * math.sin(phase * 0.9)),
      ),
      r * 0.62,
      Aurora.cyan,
      0.15,
    );
    bloom(
      Offset(
        size.width * (0.62 + 0.05 * math.sin(phase * 0.6)),
        size.height * (0.55 + 0.04 * math.cos(phase)),
      ),
      r * 0.85,
      Aurora.violet,
      0.17,
    );

    // Faint technical grid, fading out towards the edges.
    final grid = Paint()
      ..color = Aurora.ink.withValues(alpha: 0.030)
      ..strokeWidth = 1;
    const step = 56.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.75), grid);
    }
    for (double y = 0; y < size.height * 0.75; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) => oldDelegate.t != t;
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
