import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../theme/aurora.dart';

/// An image from the API, or a designed fallback when there is none.
///
/// The fallback is deterministic from a seed string, so a given project always
/// gets the same artwork and the grid looks intentional rather than half-empty.
/// That matters here because the owner supplies photography later: until then,
/// every slot still has to look like it belongs.
class MediaImage extends StatelessWidget {
  const MediaImage({
    super.key,
    required this.path,
    required this.api,
    required this.seed,
    required this.semanticLabel,
    this.aspectRatio = 16 / 10,
    this.radius = Aurora.radiusCard,
  });

  final String? path;
  final ApiClient api;
  final String seed;
  final String semanticLabel;
  final double aspectRatio;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final resolved = path == null || path!.isEmpty ? null : api.mediaUrl(path!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: resolved == null
            ? AuroraFallbackArt(seed: seed, label: semanticLabel)
            : CachedNetworkImage(
                imageUrl: resolved,
                fit: BoxFit.cover,
                fadeInDuration: Aurora.normal,
                placeholder: (context, _) => const ColoredBox(color: Aurora.canvas2),
                errorWidget: (context, _, _) =>
                    AuroraFallbackArt(seed: seed, label: semanticLabel),
                imageBuilder: (context, provider) => Image(
                  image: provider,
                  fit: BoxFit.cover,
                  semanticLabel: semanticLabel,
                ),
              ),
      ),
    );
  }
}

/// Deterministic gradient artwork derived from the seed.
class AuroraFallbackArt extends StatelessWidget {
  const AuroraFallbackArt({super.key, required this.seed, required this.label});

  final String seed;
  final String label;

  static const _palettes = <List<Color>>[
    [Aurora.teal, Aurora.cyan],
    [Aurora.cyan, Aurora.violet],
    [Aurora.violet, Aurora.teal],
    [Aurora.teal, Aurora.violet],
  ];

  int get _hash {
    var h = 0;
    for (final unit in seed.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h;
  }

  String get _monogram {
    final words = label.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '·';
    if (words.length == 1) {
      return words.first.characters.take(2).toString().toUpperCase();
    }
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hash = _hash;
    final palette = _palettes[hash % _palettes.length];
    final angle = ((hash % 4) + 1) * 0.25;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1, -1 + angle),
          end: Alignment(1, 1 - angle),
          colors: [
            palette.first.withValues(alpha: 0.34),
            Aurora.canvas2,
            palette.last.withValues(alpha: 0.30),
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _GridPainter()),
          Center(
            child: Text(
              _monogram,
              style: Aurora.display(
                40,
                weight: 700,
                color: Aurora.ink.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Aurora.ink.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    const step = 34.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
