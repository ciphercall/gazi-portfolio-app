import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_client.dart';
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
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Aurora.pagePadding,
            14,
            Aurora.pagePadding,
            0,
          ),
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
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Aurora.pagePadding),
          child: Hero(
            tag: 'project-cover-${project.slug}',
            child: MediaImage(
              path: project.coverPath,
              api: api,
              seed: project.slug,
              semanticLabel: project.title,
              aspectRatio: 16 / 9,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Aurora.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(project.title, style: Aurora.display(24))),
                  if (project.featured)
                    const AuroraChip(
                      'Featured',
                      icon: PhosphorIconsRegular.star,
                      accent: true,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(project.summary, style: Aurora.body(13.5, color: Aurora.muted)),
              const SizedBox(height: 14),
              GlassPanel(
                padding: const EdgeInsets.all(Aurora.cardPadding),
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
                    if ((project.linkedinUrl ?? '').isNotEmpty)
                      AuroraButton(
                        label: 'Posted on LinkedIn',
                        icon: PhosphorIconsRegular.linkedinLogo,
                        variant: AuroraButtonVariant.secondary,
                        onPressed: () => launchUrl(
                          Uri.parse(project.linkedinUrl!),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                  ],
                ),
              ],
              if (gallery.length > 1) ...[
                const SizedBox(height: 18),
                Text('Gallery', style: Aurora.label()),
                const SizedBox(height: 8),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: gallery.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final image = gallery[index];
                      return GestureDetector(
                        onTap: () => _openViewer(gallery, index, project.slug),
                        child: SizedBox(
                          width: 128,
                          child: Hero(
                            tag: 'gallery-${project.slug}-$index',
                            child: MediaImage(
                              path: image.path,
                              api: api,
                              seed: '${project.slug}-$index',
                              semanticLabel: image.alt.isEmpty ? project.title : image.alt,
                              aspectRatio: 4 / 3,
                              radius: Aurora.radiusControl,
                            ),
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

  void _openViewer(List<ProjectImage> images, int startIndex, String slug) {
    final api = context.read<PortfolioRepository>().api;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) => _GalleryViewer(
        images: images,
        startIndex: startIndex,
        api: api,
        slug: slug,
      ),
    );
  }
}

class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({
    required this.images,
    required this.startIndex,
    required this.api,
    required this.slug,
  });

  final List<ProjectImage> images;
  final int startIndex;
  final ApiClient api;
  final String slug;

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
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Aurora.fast,
                    child: Text(
                      '${_index + 1} of ${widget.images.length}',
                      key: ValueKey(_index),
                      style: Aurora.label(color: Aurora.muted),
                    ),
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
                padding: const EdgeInsets.all(8),
                child: Hero(
                  tag: 'gallery-${widget.slug}-$index',
                  child: _ZoomableImage(
                    image: widget.images[index],
                    api: widget.api,
                    seed: '${widget.slug}-$index',
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.images.length; i++)
                  AnimatedContainer(
                    duration: Aurora.fast,
                    curve: Aurora.easeAurora,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: i == _index ? Aurora.gradient() : null,
                      color: i == _index ? null : Aurora.line,
                      borderRadius: BorderRadius.circular(Aurora.radiusPill),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 54,
            child: Center(
              child: AnimatedSwitcher(
                duration: Aurora.fast,
                child: Text(
                  current.caption ?? '',
                  key: ValueKey('caption-$_index'),
                  textAlign: TextAlign.center,
                  style: Aurora.body(12.5, color: Aurora.muted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-screen image that can be pinched and dragged. The natural aspect
/// ratio is preserved — the previous viewer forced 3:4 and letterboxed every
/// screenshot.
class _ZoomableImage extends StatelessWidget {
  const _ZoomableImage({
    required this.image,
    required this.api,
    required this.seed,
  });

  final ProjectImage image;
  final ApiClient api;
  final String seed;

  @override
  Widget build(BuildContext context) {
    final resolved = image.path.isEmpty ? null : api.mediaUrl(image.path);

    if (resolved == null) {
      return AuroraFallbackArt(seed: seed, label: image.alt);
    }

    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: resolved,
          fit: BoxFit.contain,
          fadeInDuration: Aurora.normal,
          placeholder: (_, _) => const ColoredBox(color: Colors.transparent),
          errorWidget: (_, _, _) => AuroraFallbackArt(seed: seed, label: image.alt),
        ),
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
