import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme/aurora.dart';
import '../widgets/buttons.dart';
import '../widgets/media_image.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String? _tech;

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
          final allTech = snapshot.allTech;

          // A stale filter would silently show an empty list after the content
          // changes, so a technology that no longer exists is dropped.
          if (_tech != null && !allTech.contains(_tech)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _tech = null);
            });
          }

          final projects = _tech == null
              ? snapshot.projects
              : snapshot.projects
                    .where(
                      (project) => project.techStack.any(
                        (tech) => tech.toLowerCase() == _tech!.toLowerCase(),
                      ),
                    )
                    .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.only(bottom: 30),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                child: SectionHeading(
                  eyebrow: 'Work',
                  eyebrowIcon: PhosphorIconsRegular.squaresFour,
                  title: 'Projects',
                  lead: '${snapshot.projects.length} shipped systems. Filter by technology.',
                ),
              ),
              const SizedBox(height: 16),
              OfflineNote(repository: repository),

              if (allTech.isNotEmpty) ...[
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _tech = null),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AuroraChip(
                            'All',
                            icon: PhosphorIconsRegular.stack,
                            accent: _tech == null,
                          ),
                        ),
                      ),
                      for (final tech in allTech)
                        GestureDetector(
                          onTap: () => setState(() => _tech = tech),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AuroraChip(tech, accent: _tech == tech),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],

              if (projects.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 30, 18, 0),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Icon(
                          PhosphorIconsRegular.magnifyingGlass,
                          size: 26,
                          color: Aurora.faint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nothing matches "$_tech"',
                          style: Aurora.display(16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        AuroraButton(
                          label: 'Clear filter',
                          icon: PhosphorIconsRegular.x,
                          variant: AuroraButtonVariant.secondary,
                          onPressed: () => setState(() => _tech = null),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final project in projects)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: _ProjectCard(project: project),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final api = context.read<PortfolioRepository>().api;

    return GlassPanel(
      gradientEdge: true,
      padding: const EdgeInsets.all(14),
      onTap: () => context.go('/projects/${project.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaImage(
            path: project.coverPath,
            api: api,
            seed: project.slug,
            semanticLabel: project.title,
            radius: Aurora.radiusControl,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text(project.title, style: Aurora.display(17))),
              if (project.featured)
                const AuroraChip(
                  'Featured',
                  icon: PhosphorIconsRegular.star,
                  accent: true,
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(project.summary, style: Aurora.body(13.5, color: Aurora.muted)),
          if ((project.client ?? '').isNotEmpty || (project.role ?? '').isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              [
                if ((project.role ?? '').isNotEmpty) project.role!,
                if ((project.client ?? '').isNotEmpty) project.client!,
              ].join(' · '),
              style: Aurora.body(12.5, color: Aurora.faint),
            ),
          ],
          if (project.techStack.isNotEmpty) ...[
            const SizedBox(height: 12),
            ChipWrap(labels: project.techStack.take(5).toList()),
          ],
        ],
      ),
    );
  }
}
