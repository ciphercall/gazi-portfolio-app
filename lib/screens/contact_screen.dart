import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repository.dart';
import '../theme/aurora.dart';
import '../widgets/buttons.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';

/// Direct-message channels.
///
/// The hrefs come from the server's `links` map, so the rules for building them
/// live in one place and a change there reaches the app without a new build. A
/// channel with no href is genuinely absent, so it is listed as unset rather
/// than rendered as a button that can only fail.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const _channels = <({String key, String label, String hint, IconData icon})>[
    (
      key: 'whatsapp',
      label: 'WhatsApp',
      hint: 'Opens a chat with a message already written',
      icon: PhosphorIconsRegular.whatsappLogo,
    ),
    (
      key: 'messenger',
      label: 'Messenger',
      hint: 'Opens a direct message on Facebook',
      icon: PhosphorIconsRegular.facebookLogo,
    ),
    (
      key: 'linkedin',
      label: 'LinkedIn',
      hint: 'Profile and direct message',
      icon: PhosphorIconsRegular.linkedinLogo,
    ),
    (
      key: 'email',
      label: 'Email',
      hint: 'Opens your mail app',
      icon: PhosphorIconsRegular.envelopeSimple,
    ),
    (
      key: 'phone',
      label: 'Phone',
      hint: 'Starts a call',
      icon: PhosphorIconsRegular.phone,
    ),
    (
      key: 'github',
      label: 'GitHub',
      hint: 'Source code and repositories',
      icon: PhosphorIconsRegular.githubLogo,
    ),
    (
      key: 'facebook',
      label: 'Facebook',
      hint: 'Profile page',
      icon: PhosphorIconsRegular.facebookLogo,
    ),
    (
      key: 'website',
      label: 'Website',
      hint: 'Portfolio on the web',
      icon: PhosphorIconsRegular.globe,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<PortfolioRepository>();

    return ContentGate(
      repository: repository,
      builder: (context) {
        final profile = repository.snapshot!.profile;
        final links = profile.links;

        final available = _channels.where((channel) => links.containsKey(channel.key)).toList();
        final missing = _channels.where((channel) => !links.containsKey(channel.key)).toList();

        return ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 22, 18, 0),
              child: SectionHeading(
                eyebrow: 'Contact',
                eyebrowIcon: PhosphorIconsRegular.chatCircle,
                title: 'Reach me directly',
                lead: 'No forms and no middlemen. Every option below opens straight into a conversation.',
              ),
            ),
            const SizedBox(height: 20),

            for (final channel in available)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: GlassPanel(
                  gradientEdge: channel.key == 'whatsapp' || channel.key == 'messenger',
                  padding: const EdgeInsets.all(16),
                  onTap: () => _open(context, links[channel.key]!),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Aurora.teal.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(Aurora.radiusControl),
                        ),
                        child: Icon(channel.icon, size: 19, color: Aurora.teal),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel.label,
                              style: Aurora.body(15, weight: 600, color: Aurora.ink),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              channel.hint,
                              style: Aurora.body(12.5, color: Aurora.faint),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy ${channel.label} address',
                        onPressed: () => _copy(context, links[channel.key]!, channel.label),
                        icon: const Icon(
                          PhosphorIconsRegular.copy,
                          size: 16,
                          color: Aurora.faint,
                        ),
                      ),
                      const Icon(
                        PhosphorIconsRegular.arrowSquareOut,
                        size: 15,
                        color: Aurora.muted,
                      ),
                    ],
                  ),
                ),
              ),

            if (missing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: StatusNote(
                  tone: NoteTone.info,
                  icon: PhosphorIconsRegular.info,
                  text: 'Not configured: ${missing.map((c) => c.label).join(', ')}. '
                      'Add the handle in the admin panel to make it appear here.',
                ),
              ),

            if (available.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                child: AuroraButton(
                  label: 'Reload content',
                  icon: PhosphorIconsRegular.arrowsClockwise,
                  onPressed: repository.refresh,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _open(BuildContext context, String href) async {
    final uri = Uri.parse(href);
    final external = href.startsWith('http');
    await launchUrl(
      uri,
      mode: external ? LaunchMode.externalApplication : LaunchMode.platformDefault,
    );
  }

  Future<void> _copy(BuildContext context, String href, String label) async {
    final value = href
        .replaceFirst('mailto:', '')
        .replaceFirst('tel:', '')
        .replaceFirst('https://wa.me/', '+')
        .replaceFirst('https://m.me/', '@')
        .replaceFirst('https://', '');

    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        backgroundColor: Aurora.canvas2,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
