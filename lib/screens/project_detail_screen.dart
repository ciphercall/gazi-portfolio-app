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
import '../widgets/rich_body.dart';
import '../widgets/surfaces.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  Future<void> _loadDetail() async {
    final repository = context.read<PortfolioRepository>();
    final cached = repository.snapshot?.projects
        .where((project) => project.slug == widget.slug)
        .firstOrNull;

    // A cached body means the detail endpoint has already been read.
    if (cached != null && cached.body.isNotEmpty) return;

    setState(() => _loadingDetail = true);
    try {
      await repository.loadProjectDetail(widget.slug);
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<PortfolioRepository>();
    final project = repository.snapshot?.projects
        .where((item) => item.slug == widget.slug)
        .firstOrNull;

    if (project == null) {
      return _NotFound(repository: repository);
    }

    final api = repository.api;
    final gallery = <ProjectImage>[
      if (project.coverPath != null && project.coverPath!.isNotEmpty)
        ProjectImage(
          path: project.coverPath!,
          alt: project.title,
          caption: null,
          width: 0,
          height: 0,
        ),
      ...project.images,
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 34),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AuroraButton(
              label: 'Back',
              icon: PhosphorIconsRegular.arrowLeft,
              variant: AuroraButtonVariant.ghost,
              onPressed: () => context.go('/projects'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: MediaImage(
            path: project.coverPath,
            api: api,
            seed: project.slug,
            semanticLabel: project.title,
            aspectRatio: 16 / 9,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(project.title, style: Aurora.display(26))),
                  if (project.featured)
                    const AuroraChip(
                      'Featured',
                      icon: PhosphorIconsRegular.star,
                      accent: true,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(project.summary, style: Aurora.body(15, color: Aurora.muted)),
              const SizedBox(height: 18),
              GlassPanel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if ((project.role ?? '').isNotEmpty)
                      DetailRow(
                        label: 'Role',
                        value: project.role!,
                        icon: PhosphorIconsRegular.identificationBadge,
                      ),
                    if ((project.client ?? '').isNotEmpty)
                      DetailRow(
                        label: 'Client',
                        value: project.client!,
                        icon: PhosphorIconsRegular.buildings,
                      ),
                    if (project.year != null)
                      DetailRow(
                        label: 'Year',
                        value: '${project.year}',
                        icon: PhosphorIconsRegular.calendarBlank,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (project.body.isNotEmpty)
                RichBody(project.body)
              else if (_loadingDetail)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SkeletonBox(height: 80, radius: Aurora.radiusCard),
                )
              else
                Text(
                  'The full write-up for this project is not available offline yet.',
                  style: Aurora.body(13.5, color: Aurora.faint),
                ),
              if (project.techStack.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Technologies', style: Aurora.label()),
                const SizedBox(height: 10),
                ChipWrap(labels: project.techStack),
              ],
              if ((project.liveUrl ?? '').isNotEmpty || (project.repoUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if ((project.liveUrl ?? '').isNotEmpty)
                      AuroraButton(
                        label: 'Open live site',
                        icon: PhosphorIconsRegular.arrowSquareOut,
                        onPressed: () =>
                            launchUrl(Uri.parse(project.liveUrl!), mode: LaunchMode.externalApplication),
                      ),
                    if ((project.repoUrl ?? '').isNotEmpty)
                      AuroraButton(
                        label: 'Source code',
                        icon: PhosphorIconsRegular.githubLogo,
                        variant: AuroraButtonVariant.secondary,
                        onPressed: () =>
                            launchUrl(Uri.parse(project.repoUrl!), mode: LaunchMode.externalApplication),
                      ),
                  ],
                ),
              ],
              if (gallery.length > 1) ...[
                const SizedBox(height: 26),
                Text('Gallery', style: Aurora.label()),
                const SizedBox(height: 10),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: gallery.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final image = gallery[index];
                      return GestureDetector(
                        onTap: () => _openViewer(gallery, index),
                        child: SizedBox(
                          width: 140,
                          child: MediaImage(
                            path: image.path,
                            api: api,
                            seed: '${project.slug}-$index',
                            semanticLabel: image.alt.isEmpty ? project.title : image.alt,
                            aspectRatio: 4 / 3,
                            radius: Aurora.radiusControl,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _openViewer(List<ProjectImage> images, int startIndex) {
    final api = context.read<PortfolioRepository>().api;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) => _GalleryViewer(
        images: images,
        startIndex: startIndex,
        api: api,
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({
    required this.images,
    required this.startIndex,
    required this.api,
  });

  final List<ProjectImage> images;
  final int startIndex;
  final dynamic api;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _controller = PageController(initialPage: widget.startIndex);
  late int _index = widget.startIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.images[_index];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_index + 1} of ${widget.images.length}',
                    style: Aurora.label(color: Aurora.muted),
                  ),
                ),
                // A labelled control, not a bare glyph.
                AuroraButton(
                  label: 'Close',
                  icon: PhosphorIconsRegular.x,
                  variant: AuroraButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (next) => setState(() => _index = next),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(14),
                child: Center(
                  child: MediaImage(
                    path: widget.images[index].path,
                    api: widget.api,
                    seed: 'viewer-$index',
                    semanticLabel: widget.images[index].alt,
                    aspectRatio: 3 / 4,
                    radius: Aurora.radiusControl,
                  ),
                ),
              ),
            ),
          ),
          if ((current.caption ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
              child: Text(
                current.caption!,
                textAlign: TextAlign.center,
                style: Aurora.body(13, color: Aurora.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.repository});

  final PortfolioRepository repository;

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
              const Icon(PhosphorIconsRegular.magnifyingGlass, size: 28, color: Aurora.faint),
              const SizedBox(height: 14),
              Text('Project not found', style: Aurora.display(18)),
              const SizedBox(height: 8),
              Text(
                repository.hasContent
                    ? 'That project is not in the published list.'
                    : 'Content has not loaded yet.',
                textAlign: TextAlign.center,
                style: Aurora.body(13.5, color: Aurora.muted),
              ),
              const SizedBox(height: 18),
              AuroraButton(
                label: 'Back to projects',
                icon: PhosphorIconsRegular.arrowLeft,
                onPressed: () => context.go('/projects'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
