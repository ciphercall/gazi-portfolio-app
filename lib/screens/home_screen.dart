import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../theme/aurora.dart';
import '../widgets/aurora.dart';
import '../widgets/buttons.dart';
import '../widgets/experience_card.dart';
import '../widgets/media_image.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          final profile = snapshot.profile;
          final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

          final featured = snapshot.featuredProjects;
          final preview = snapshot.allExperiences.take(3).toList(growable: false);

          return ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              _Reveal(
                enabled: !reduceMotion,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AuroraChip(
                            'Available for work',
                            icon: PhosphorIconsRegular.circle,
                            accent: true,
                          ),
                          const Spacer(),
                          AuroraButton(
                            label: 'Settings',
                            icon: PhosphorIconsRegular.gearSix,
                            variant: AuroraButtonVariant.ghost,
                            onPressed: () => context.go('/settings'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _HeroName(profile.fullName),
                      const SizedBox(height: 10),
                      Text(
                        profile.headline,
                        style: Aurora.body(16, weight: 600, color: Aurora.teal),
                      ),
                      if (profile.subheadline.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          profile.subheadline,
                          style: Aurora.body(14.5, color: Aurora.muted),
                        ),
                      ],
                      if (profile.location.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              PhosphorIconsRegular.mapPin,
                              size: 14,
                              color: Aurora.faint,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              profile.location,
                              style: Aurora.body(13, color: Aurora.faint),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          AuroraButton(
                            label: 'View projects',
                            icon: PhosphorIconsRegular.arrowRight,
                            onPressed: () => context.go('/projects'),
                          ),
                          AuroraButton(
                            label: 'Download CV',
                            icon: PhosphorIconsRegular.downloadSimple,
                            variant: AuroraButtonVariant.secondary,
                            onPressed: () => context.go('/cv'),
                          ),
                          AuroraButton(
                            label: 'Contact me',
                            icon: PhosphorIconsRegular.chatCircle,
                            variant: AuroraButtonVariant.ghost,
                            onPressed: () => context.go('/contact'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 26),
              OfflineNote(repository: repository),

              _StatsRow(
                years: _yearsOfExperience(snapshot.allExperiences),
                roles: snapshot.allExperiences.length,
                projects: snapshot.projects.length,
              ),

              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: SectionHeading(
                  eyebrow: 'Profile',
                  eyebrowIcon: PhosphorIconsRegular.userCircle,
                  title: 'What I do',
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  profile.summary,
                  style: Aurora.body(15, color: Aurora.muted),
                ),
              ),

              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SectionHeading(
                  eyebrow: 'Experience',
                  eyebrowIcon: PhosphorIconsRegular.briefcase,
                  title: 'Where I have worked',
                  lead: '${snapshot.experiences.length} full-time roles'
                      '${snapshot.partTimeExperiences.isEmpty ? '' : ' and ${snapshot.partTimeExperiences.length} part-time'}',
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    for (final experience in preview)
                      ExperienceCard(experience: experience, compact: true),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
                child: AuroraButton(
                  label: 'See all experience',
                  icon: PhosphorIconsRegular.arrowRight,
                  variant: AuroraButtonVariant.secondary,
                  onPressed: () => context.go('/experience'),
                ),
              ),

              if (featured.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: SectionHeading(
                    eyebrow: 'Selected work',
                    eyebrowIcon: PhosphorIconsRegular.squaresFour,
                    title: 'Featured projects',
                  ),
                ),
                const SizedBox(height: 16),
                for (final project in featured)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: GlassPanel(
                      gradientEdge: true,
                      padding: const EdgeInsets.all(14),
                      onTap: () => context.go('/projects/${project.slug}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MediaImage(
                            path: project.coverPath,
                            api: repository.api,
                            seed: project.slug,
                            semanticLabel: project.title,
                            radius: Aurora.radiusControl,
                          ),
                          const SizedBox(height: 14),
                          Text(project.title, style: Aurora.display(17)),
                          const SizedBox(height: 7),
                          Text(
                            project.summary,
                            style: Aurora.body(13.5, color: Aurora.muted),
                          ),
                          if (project.techStack.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ChipWrap(labels: project.techStack.take(5).toList()),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.arrowRight,
                                size: 14,
                                color: Aurora.teal,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'View case study',
                                style: Aurora.body(13, weight: 600, color: Aurora.teal),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: AuroraButton(
                    label: 'All projects',
                    icon: PhosphorIconsRegular.squaresFour,
                    variant: AuroraButtonVariant.secondary,
                    onPressed: () => context.go('/projects'),
                  ),
                ),
              ],

              if (snapshot.skillGroups.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: SectionHeading(
                    eyebrow: 'Toolkit',
                    eyebrowIcon: PhosphorIconsRegular.stack,
                    title: 'Skills',
                  ),
                ),
                const SizedBox(height: 16),
                for (final group in snapshot.skillGroups)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.category,
                          style: Aurora.body(13, weight: 600, color: Aurora.ink),
                        ),
                        const SizedBox(height: 9),
                        ChipWrap(labels: group.items),
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  static int _yearsOfExperience(List<dynamic> experiences) {
    DateTime? earliest;
    for (final experience in experiences) {
      final parsed = DateTime.tryParse('${experience.startDate}');
      if (parsed == null) continue;
      if (earliest == null || parsed.isBefore(earliest)) earliest = parsed;
    }
    if (earliest == null) return 0;
    return DateTime.now().year - earliest.year;
  }
}

/// The name, with the surname in the accent gradient.
class _HeroName extends StatelessWidget {
  const _HeroName(this.fullName);

  final String fullName;

  @override
  Widget build(BuildContext context) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return Text(fullName, style: Aurora.display(38));
    }
    final first = parts.sublist(0, parts.length - 1).join(' ');
    final last = parts.last;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Text('$first ', style: Aurora.display(38)),
        AuroraText(last, style: Aurora.display(38)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.years, required this.roles, required this.projects});

  final int years;
  final int roles;
  final int projects;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String value, String label})>[
      (icon: PhosphorIconsRegular.calendarCheck, value: '$years+', label: 'Years'),
      (icon: PhosphorIconsRegular.briefcase, value: '$roles', label: 'Roles'),
      (icon: PhosphorIconsRegular.squaresFour, value: '$projects', label: 'Projects'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Container(width: 1, height: 40, color: Aurora.line),
              Expanded(
                child: Column(
                  children: [
                    Icon(items[i].icon, size: 17, color: Aurora.teal),
                    const SizedBox(height: 7),
                    Text(items[i].value, style: Aurora.display(20)),
                    const SizedBox(height: 2),
                    Text(items[i].label, style: Aurora.label()),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fade + rise on first build. Skipped entirely when animations are disabled.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, required this.enabled});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Aurora.slow,
      curve: Aurora.easeAurora,
      builder: (context, value, inner) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: inner),
      ),
      child: child,
    );
  }
}
