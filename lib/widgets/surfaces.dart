import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/aurora.dart';

/// A translucent surface with a hairline border — the app's basic container.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.strong = false,
    this.radius = Aurora.radiusCard,
    this.gradientEdge = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool strong;
  final double radius;
  final bool gradientEdge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: strong ? Aurora.glassStrong(radius: radius) : Aurora.glass(radius: radius),
      child: child,
    );

    final wrapped = gradientEdge
        ? CustomPaint(painter: _HairlinePainter(radius: radius), child: content)
        : content;

    if (onTap == null) return wrapped;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: wrapped,
      ),
    );
  }
}

/// A one-pixel gradient edge that reads as light catching the corner.
class _HairlinePainter extends CustomPainter {
  _HairlinePainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Aurora.teal.withValues(alpha: 0.55),
          Colors.transparent,
          Colors.transparent,
          Aurora.violet.withValues(alpha: 0.45),
        ],
        stops: const [0, 0.36, 0.62, 1],
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_HairlinePainter oldDelegate) => oldDelegate.radius != radius;
}

/// Small uppercase eyebrow plus a title. Structure is carried by the label text,
/// never by colour alone.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.eyebrow,
    this.title,
    this.lead,
    this.eyebrowIcon,
  });

  final String eyebrow;
  final String? title;
  final String? lead;
  final IconData? eyebrowIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (eyebrowIcon != null) ...[
              Icon(eyebrowIcon, size: 13, color: Aurora.teal),
              const SizedBox(width: 7),
            ],
            // A short accent rule next to the label — decoration only, the text
            // carries the meaning.
            Container(
              width: 16,
              height: 2,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: Aurora.gradient(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(eyebrow.toUpperCase(), style: Aurora.label()),
          ],
        ),
        if (title != null) ...[
          const SizedBox(height: 10),
          Text(title!, style: Aurora.display(26)),
        ],
        if (lead != null) ...[
          const SizedBox(height: 8),
          Text(lead!, style: Aurora.body(15, color: Aurora.muted)),
        ],
      ],
    );
  }
}

/// A technology / tag chip. Always icon + text.
class AuroraChip extends StatelessWidget {
  const AuroraChip(this.label, {super.key, this.icon, this.accent = false});

  final String label;
  final IconData? icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: accent ? Aurora.teal.withValues(alpha: 0.10) : Aurora.panel,
        borderRadius: BorderRadius.circular(Aurora.radiusPill),
        border: Border.all(
          color: accent ? Aurora.teal.withValues(alpha: 0.45) : Aurora.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: accent ? Aurora.teal : Aurora.muted),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Aurora.body(12, weight: 500, color: accent ? Aurora.teal : Aurora.ink),
          ),
        ],
      ),
    );
  }
}

/// Wrap of chips with consistent spacing.
class ChipWrap extends StatelessWidget {
  const ChipWrap({super.key, required this.labels, this.icon, this.accent = false});

  final List<String> labels;
  final IconData? icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: labels
          .map((label) => AuroraChip(label, icon: icon, accent: accent))
          .toList(growable: false),
    );
  }
}

/// Label / value pair. Read-only values look read-only: sunk, muted, no tap
/// affordance, and never coloured like something interactive.
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 14, color: Aurora.faint),
            ),
            const SizedBox(width: 9),
          ],
          SizedBox(
            width: 104,
            child: Text(label, style: Aurora.body(13, color: Aurora.faint)),
          ),
          Expanded(
            child: Text(
              value,
              style: Aurora.body(13.5, weight: 500, color: Aurora.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// A quiet status line. Offline is stated plainly rather than hidden.
class StatusNote extends StatelessWidget {
  const StatusNote({super.key, required this.text, this.icon, this.tone = NoteTone.info});

  final String text;
  final IconData? icon;
  final NoteTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      NoteTone.info => Aurora.muted,
      NoteTone.ok => Aurora.teal,
      NoteTone.warn => Aurora.rose,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Aurora.radiusControl),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon ?? PhosphorIconsRegular.info, size: 14, color: color),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: Aurora.body(12.5, color: color))),
        ],
      ),
    );
  }
}

enum NoteTone { info, ok, warn }

/// Skeleton placeholder so a loading screen never looks broken or blank.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = 8});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Aurora.panel,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
