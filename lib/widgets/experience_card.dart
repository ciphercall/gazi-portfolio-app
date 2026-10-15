import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/models.dart';
import '../theme/aurora.dart';
import 'surfaces.dart';

/// One entry on the career timeline.
///
/// The node + rule on the left is what makes a list of roles read as a timeline
/// rather than a stack of cards, and it costs one `Container`.
class ExperienceCard extends StatelessWidget {
  const ExperienceCard({super.key, required this.experience, this.compact = false});

  final Experience experience;
  final bool compact;

  static String formatRange(Experience experience) {
    final format = DateFormat('MMM yyyy');
    final start = DateTime.tryParse(experience.startDate);
    final begin = start == null ? experience.startDate : format.format(start);

    if (experience.isCurrent || experience.endDate == null) {
      return '$begin - Present';
    }
    final end = DateTime.tryParse(experience.endDate!);
    final finish = end == null ? experience.endDate! : format.format(end);
    return '$begin - $finish';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail.
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: Aurora.gradient(),
                    boxShadow: experience.isCurrent
                        ? [
                            BoxShadow(
                              color: Aurora.teal.withValues(alpha: 0.45),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.only(top: 5),
                    color: Aurora.line,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(experience.title, style: Aurora.display(17.5)),
                      ),
                      if (experience.isCurrent) ...[
                        const SizedBox(width: 8),
                        const AuroraChip(
                          'Current',
                          icon: PhosphorIconsRegular.checkCircle,
                          accent: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    experience.company,
                    style: Aurora.body(14, weight: 600, color: Aurora.teal),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      _meta(PhosphorIconsRegular.calendarBlank, formatRange(experience)),
                      if ((experience.location ?? '').isNotEmpty)
                        _meta(PhosphorIconsRegular.mapPin, experience.location!),
                      _meta(
                        PhosphorIconsRegular.clockUser,
                        experience.isPartTime ? 'Part-time' : 'Full-time',
                      ),
                    ],
                  ),
                  if (experience.summary.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    Text(
                      experience.summary,
                      style: Aurora.body(14, color: Aurora.muted),
                    ),
                  ],
                  if (!compact && experience.bullets.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final bullet in experience.bullets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(top: 9, right: 10),
                              decoration: BoxDecoration(
                                gradient: Aurora.gradient(),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                bullet,
                                style: Aurora.body(13.5, color: Aurora.muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (experience.tags.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    ChipWrap(labels: experience.tags),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.5, color: Aurora.faint),
        const SizedBox(width: 5),
        Text(text, style: Aurora.body(12.5, color: Aurora.faint)),
      ],
    );
  }
}
