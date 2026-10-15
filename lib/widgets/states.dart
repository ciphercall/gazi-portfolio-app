import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/repository.dart';
import '../theme/aurora.dart';
import 'buttons.dart';
import 'surfaces.dart';

/// Shared loading / error / offline presentation.
///
/// Centralised so every screen answers the same three situations the same way:
/// skeleton rather than blank while loading, a real explanation with a retry on
/// failure, and a quiet note — never a hidden state — when the content on screen
/// came from the cache.

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.blocks = 3});

  final int blocks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 26, width: 180),
          const SizedBox(height: 14),
          const SkeletonBox(height: 14, width: 260),
          const SizedBox(height: 26),
          for (var i = 0; i < blocks; i++) ...[
            const SkeletonBox(height: 92, radius: Aurora.radiusCard),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassPanel(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(PhosphorIconsRegular.cloudSlash, size: 30, color: Aurora.rose),
              const SizedBox(height: 14),
              Text('Nothing loaded yet', style: Aurora.display(19), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                message ?? 'The portfolio could not be reached.',
                textAlign: TextAlign.center,
                style: Aurora.body(13.5, color: Aurora.muted),
              ),
              const SizedBox(height: 6),
              Text(
                'Check that the stack is running, then try again.',
                textAlign: TextAlign.center,
                style: Aurora.body(12, color: Aurora.faint),
              ),
              const SizedBox(height: 18),
              AuroraButton(
                label: 'Try again',
                icon: PhosphorIconsRegular.arrowsClockwise,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the offline note only when there is content to show.
class OfflineNote extends StatelessWidget {
  const OfflineNote({super.key, required this.repository});

  final PortfolioRepository repository;

  @override
  Widget build(BuildContext context) {
    if (!repository.isOffline || !repository.hasContent) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: StatusNote(
        tone: NoteTone.info,
        icon: PhosphorIconsRegular.cloudArrowDown,
        text: 'Showing saved content. Pull down to refresh.',
      ),
    );
  }
}

/// Wraps a screen body with the three states above. Returns the child only when
/// there is something to render.
class ContentGate extends StatelessWidget {
  const ContentGate({
    super.key,
    required this.repository,
    required this.builder,
  });

  final PortfolioRepository repository;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final snapshot = repository.snapshot;

    if (snapshot == null) {
      if (repository.state == LoadState.error) {
        return ErrorPanel(message: repository.error, onRetry: repository.refresh);
      }
      return const LoadingSkeleton();
    }

    return builder(context);
  }
}
