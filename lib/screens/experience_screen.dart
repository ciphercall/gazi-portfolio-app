import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../widgets/experience_card.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';
import '../theme/aurora.dart';

class ExperienceScreen extends StatelessWidget {
  const ExperienceScreen({super.key});

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
          final fullTime = snapshot.experiences;
          final partTime = snapshot.partTimeExperiences;

          return ListView(
            padding: const EdgeInsets.only(bottom: 30),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 22, 18, 0),
                child: SectionHeading(
                  eyebrow: 'Career',
                  eyebrowIcon: PhosphorIconsRegular.briefcase,
                  title: 'Experience',
                  lead: 'Every role in order, newest first. Full-time and part-time are listed separately.',
                ),
              ),
              const SizedBox(height: 20),
              OfflineNote(repository: repository),

              if (fullTime.isNotEmpty) ...[
                _GroupHeader(
                  label: 'Full-time',
                  count: fullTime.length,
                  icon: PhosphorIconsRegular.clockUser,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      for (final experience in fullTime)
                        ExperienceCard(experience: experience),
                    ],
                  ),
                ),
              ],

              if (partTime.isNotEmpty) ...[
                const SizedBox(height: 12),
                _GroupHeader(
                  label: 'Part-time',
                  count: partTime.length,
                  icon: PhosphorIconsRegular.clockCountdown,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      for (final experience in partTime)
                        ExperienceCard(experience: experience),
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
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.count, required this.icon});

  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Aurora.teal),
          const SizedBox(width: 8),
          Text(
            label,
            style: Aurora.body(14, weight: 600, color: Aurora.ink),
          ),
          const SizedBox(width: 8),
          AuroraChip('$count', icon: PhosphorIconsRegular.hash),
        ],
      ),
    );
  }
}
