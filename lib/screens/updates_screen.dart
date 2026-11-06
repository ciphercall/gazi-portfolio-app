import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/aurora.dart';
import '../widgets/buttons.dart';
import '../widgets/media_image.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';

/// What has gone out on LinkedIn.
///
/// The web admin prepares and publishes these posts; the app simply shows the
/// published ones, newest first, with a link to the live post. That is the whole
/// point of the endpoint: the portfolio and the LinkedIn feed stay in step
/// without the app needing any credentials of its own.
class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<PortfolioRepository>();

    return RefreshIndicator(
      color: Aurora.teal,
      backgroundColor: Aurora.canvas2,
      onRefresh: repository.refresh,
      child: ContentGate(
        repository: repository,
        builder: (context) {
          final snapshot = repository.snapshot!;
          final posts = snapshot.posts;
          final api = repository.api;

          return ListView(
            padding: const EdgeInsets.only(bottom: 30),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                child: SectionHeading(
                  eyebrow: 'Updates',
                  eyebrowIcon: PhosphorIconsRegular.megaphone,
                  title: 'Posted on LinkedIn',
                  lead: posts.isEmpty
                      ? 'Nothing has been published yet.'
                      : '${posts.length} post${posts.length == 1 ? '' : 's'} about the work in this portfolio.',
                ),
              ),
              const SizedBox(height: 16),
              OfflineNote(repository: repository),

              if (posts.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Icon(
                          PhosphorIconsRegular.megaphone,
                          size: 26,
                          color: Aurora.faint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No posts yet',
                          style: Aurora.display(16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Published posts appear here automatically. The schedule is managed from the '
                          'portfolio admin panel.',
                          style: Aurora.body(13, color: Aurora.muted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final post in posts)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: _PostCard(post: post, api: api),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.api});

  final SocialPost post;
  final dynamic api;

  String get _postedLabel {
    final parsed = DateTime.tryParse(post.postedAt);
    if (parsed == null) return 'Posted';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = parsed.toLocal();
    return 'Posted ${local.day} ${months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      gradientEdge: true,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((post.imageUrl ?? '').isNotEmpty)
            MediaImage(
              path: post.imageUrl,
              api: api,
              seed: post.id,
              semanticLabel: post.title,
              aspectRatio: 1200 / 627,
              radius: Aurora.radiusControl,
            ),
          const SizedBox(height: 14),
          Text(post.title, style: Aurora.display(17)),
          if (post.summary.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(post.summary, style: Aurora.body(13.5, color: Aurora.muted)),
          ],
          const SizedBox(height: 12),
          Text(_postedLabel, style: Aurora.body(12.5, color: Aurora.faint)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AuroraButton(
                label: 'Open on LinkedIn',
                icon: PhosphorIconsRegular.arrowSquareOut,
                onPressed: () => launchUrl(
                  Uri.parse(post.permalink),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              if (post.isProjectPost && (post.subjectSlug ?? '').isNotEmpty)
                AuroraButton(
                  label: 'View case study',
                  icon: PhosphorIconsRegular.squaresFour,
                  variant: AuroraButtonVariant.secondary,
                  onPressed: () => context.go('/projects/${post.subjectSlug}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
