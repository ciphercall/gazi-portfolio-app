import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../theme/aurora.dart';
import '../widgets/aurora.dart';
import '../widgets/buttons.dart';
import '../widgets/experience_card.dart';
import '../widgets/media_image.dart';
import '../widgets/motion.dart';
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

          final featured = snapshot.featuredProjects;
          final preview = snapshot.allExperiences.take(3).toList(growable: false);

          return ListView(
            padding: const EdgeInsets.only(bottom: 22),
            children: [
              Reveal(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Aurora.pagePadding,
                    16,
                    Aurora.pagePadding,
                    0,
                  ),
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
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HeroName(profile.fullName, size: 30),
                                const SizedBox(height: 8),
                                Text(
                                  profile.headline,
                                  style: Aurora.body(
                                    15,
                                    weight: 600,
                                    color: Aurora.teal,
                                  ),
                                ),
                                if (profile.subheadline.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    profile.subheadline,
                                    style: Aurora.body(13.5, color: Aurora.muted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _PortraitTile(
                            path: profile.avatarPath,
                            api: repository.api,
                            name: profile.fullName,
                          ),
                        ],
                      ),
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
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
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
                          if (snapshot.posts.isNotEmpty)
                            AuroraButton(
                              label: 'LinkedIn updates',
                              icon: PhosphorIconsRegular.megaphone,
                              variant: AuroraButtonVariant.ghost,
                              onPressed: () => context.go('/updates'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              OfflineNote(repository: repository),

              _StatsRow(
                years: _yearsOfExperience(snapshot.allExperiences),
                roles: snapshot.allExperiences.length,
                projects: snapshot.projects.length,
              ),

              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Aurora.pagePadding),
                child: SectionHeading(
                  eyebrow: 'Profile',
                  eyebrowIcon: PhosphorIconsRegular.userCircle,
                  title: 'What I do',
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Aurora.pagePadding),
                child: Text(
                  profile.summary,
                  style: Aurora.body(15, color: Aurora.muted),
                ),
              ),

              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Aurora.pagePadding),
                child: SectionHeading(
                  eyebrow: 'Experience',
                  eyebrowIcon: PhosphorIconsRegular.briefcase,
                  title: 'Where I have worked',
                  lead: '${snapshot.experiences.length} full-time roles'
                      '${snapshot.partTimeExperiences.isEmpty ? '' : ' and ${snapshot.partTimeExperiences.length} part-time'}',
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Aurora.pagePadding),
                child: Column(
                  children: [
                    for (var i = 0; i < preview.length; i++)
                      Reveal(
                        delay: Duration(milliseconds: 45 * i),
                        child: ExperienceCard(
                          experience: preview[i],
                          compact: true,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Aurora.pagePadding,
                  2,
                  Aurora.pagePadding,
                  0,
                ),
                child: AuroraButton(
                  label: 'See all experience',
                  icon: PhosphorIconsRegular.arrowRight,
                  variant: AuroraButtonVariant.secondary,
                  onPressed: () => context.go('/experience'),
                ),
              ),

              if (featured.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Aurora.pagePadding),
                  child: SectionHeading(
                    eyebrow: 'Selected work',
                    eyebrowIcon: PhosphorIconsRegular.squaresFour,
                    title: 'Featured projects',
                  ),
                ),
                const SizedBox(height: 12),
                _FeaturedProjects(projects: featured, api: repository.api),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Aurora.pagePadding),
                  child: AuroraButton(
                    label: 'All projects',
                    icon: PhosphorIconsRegular.squaresFour,
                    variant: AuroraButtonVariant.secondary,
                    onPressed: () => context.go('/projects'),
                  ),
                ),
              ],

              if (snapshot.skillGroups.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Aurora.pagePadding),
                  child: SectionHeading(
                    eyebrow: 'Toolkit',
                    eyebrowIcon: PhosphorIconsRegular.stack,
                    title: 'Skills',
                  ),
                ),
                const SizedBox(height: 12),
                _SkillsGrid(groups: snapshot.skillGroups),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Aurora.pagePadding,
                    2,
                    Aurora.pagePadding,
                    0,
                  ),
                  child: TechMarquee(
                    items: [
                      for (final group in snapshot.skillGroups) ...group.items,
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

  static double _yearsOfExperience(List<dynamic> experiences) {
    DateTime? earliest;
    for (final experience in experiences) {
      final parsed = DateTime.tryParse('${experience.startDate}');
      if (parsed == null) continue;
      if (earliest == null || parsed.isBefore(earliest)) earliest = parsed;
    }
    if (earliest == null) return 0;
    final years = DateTime.now().difference(earliest).inDays / 365.25;
    return (years * 2).floor() / 2;
  }
}

/// The name, with the surname in the accent gradient.
class _HeroName extends StatelessWidget {
  const _HeroName(this.fullName, {this.size = 34});

  final String fullName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return Text(fullName, style: Aurora.display(size));
    }
    final first = parts.sublist(0, parts.length - 1).join(' ');
    final last = parts.last;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Text('$first ', style: Aurora.display(size)),
        AuroraText(last, style: Aurora.display(size)),
      ],
    );
  }
}

/// The same portrait the web hero uses. Falls back to the shared monogram art
/// when the profile has no avatar or the image cannot be loaded.
class _PortraitTile extends StatelessWidget {
  const _PortraitTile({required this.path, required this.api, required this.name});

  final String? path;
  final ApiClient api;
  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: Hero(
        tag: 'profile-avatar',
        child: MediaImage(
          path: path,
          api: api,
          seed: name,
          semanticLabel: 'Portrait of $name',
          aspectRatio: 4 / 5,
          radius: Aurora.radiusCard,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.years, required this.roles, required this.projects});

  final double years;
  final int roles;
  final int projects;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, double value, int decimals, String suffix, String label})>[
      (
        icon: PhosphorIconsRegular.calendarCheck,
        value: years,
        decimals: years == years.roundToDouble() ? 0 : 1,
        suffix: '+',
        label: 'Years',
      ),
      (
        icon: PhosphorIconsRegular.briefcase,
        value: roles.toDouble(),
        decimals: 0,
        suffix: '',
        label: 'Roles',
      ),
      (
        icon: PhosphorIconsRegular.squaresFour,
        value: projects.toDouble(),
        decimals: 0,
        suffix: '',
        label: 'Projects',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Aurora.pagePadding),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) Container(width: 1, height: 34, color: Aurora.line),
              Expanded(
                child: Column(
                  children: [
                    Icon(items[i].icon, size: 15, color: Aurora.teal),
                    const SizedBox(height: 5),
                    CountUp(
                      value: items[i].value,
                      decimals: items[i].decimals,
                      suffix: items[i].suffix,
                      style: Aurora.display(18),
                    ),
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

/// Featured work: two dense columns as soon as the screen allows it.
class _FeaturedProjects extends StatelessWidget {
  const _FeaturedProjects({required this.projects, required this.api});

  final List<Project> projects;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 2 : 1;
        final width = (constraints.maxWidth -
                Aurora.pagePadding * 2 -
                Aurora.gap * (columns - 1)) /
            columns;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Aurora.pagePadding),
          child: Wrap(
            spacing: Aurora.gap,
            runSpacing: Aurora.gap,
            children: [
              for (var i = 0; i < projects.length; i++)
                SizedBox(
                  width: width,
                  child: Reveal(
                    delay: Duration(milliseconds: 55 * i),
                    child: PressScale(
                      child: GlassPanel(
                        gradientEdge: true,
                        padding: const EdgeInsets.all(Aurora.cardPadding),
                        onTap: () => context.go('/projects/${projects[i].slug}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: 'project-cover-${projects[i].slug}',
                              child: MediaImage(
                                path: projects[i].coverPath,
                                api: api,
                                seed: projects[i].slug,
                                semanticLabel: projects[i].title,
                                radius: Aurora.radiusControl,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(projects[i].title, style: Aurora.display(15.5)),
                            const SizedBox(height: 5),
                            Text(
                              projects[i].summary,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Aurora.body(12.5, color: Aurora.muted),
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                Icon(
                                  PhosphorIconsRegular.arrowRight,
                                  size: 13,
                                  color: Aurora.teal,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'View case study',
                                  style: Aurora.body(
                                    12.5,
                                    weight: 600,
                                    color: Aurora.teal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Skill groups as a dense two-column grid, followed by a marquee elsewhere.
class _SkillsGrid extends StatelessWidget {
  const _SkillsGrid({required this.groups});

  final List<SkillGroup> groups;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 2 : 1;
        final width = (constraints.maxWidth -
                Aurora.pagePadding * 2 -
                Aurora.gap * (columns - 1)) /
            columns;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Aurora.pagePadding),
          child: Wrap(
            spacing: Aurora.gap,
            runSpacing: Aurora.gap,
            children: [
              for (var i = 0; i < groups.length; i++)
                SizedBox(
                  width: width,
                  child: Reveal(
                    delay: Duration(milliseconds: 45 * i),
                    child: GlassPanel(
                      padding: const EdgeInsets.all(Aurora.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groups[i].category,
                            style: Aurora.body(12.5, weight: 600),
                          ),
                          const SizedBox(height: 7),
                          ChipWrap(labels: groups[i].items),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
