import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../theme/aurora.dart';
import '../widgets/buttons.dart';
import '../widgets/surfaces.dart';

/// App settings.
///
/// The server address is the only thing here that genuinely needs changing: an
/// emulator reaches the host on `10.0.2.2`, a physical phone needs the machine's
/// LAN address, and a tunnel needs a public hostname. Hard-coding one of those
/// would make the app work on exactly one device.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<PortfolioRepository>().api.baseUrl,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repository = context.read<PortfolioRepository>();
    setState(() => _saving = true);
    try {
      await repository.setBaseUrl(_controller.text);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<PortfolioRepository>();
    final snapshot = repository.snapshot;
    final synced = repository.lastSyncedAt;

    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 22, 18, 0),
          child: SectionHeading(
            eyebrow: 'Settings',
            eyebrowIcon: PhosphorIconsRegular.gearSix,
            title: 'App settings',
          ),
        ),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: GlassPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.wifiHigh, size: 16, color: Aurora.teal),
                    const SizedBox(width: 9),
                    Text('Portfolio server', style: Aurora.body(15, weight: 600)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'An Android emulator reaches this machine on 10.0.2.2. '
                  'A physical phone needs the machine\'s LAN address, for example '
                  'http://192.168.0.10:8023.',
                  style: Aurora.body(12.5, color: Aurora.faint),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: Aurora.body(14, color: Aurora.ink),
                  decoration: InputDecoration(
                    hintText: ApiClient.defaultBaseUrl,
                    hintStyle: Aurora.body(14, color: Aurora.faint),
                    filled: true,
                    fillColor: Aurora.panel,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Aurora.radiusControl),
                      borderSide: const BorderSide(color: Aurora.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Aurora.radiusControl),
                      borderSide: const BorderSide(color: Aurora.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Aurora.radiusControl),
                      borderSide: const BorderSide(color: Aurora.teal),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AuroraButton(
                  label: _saving ? 'Saving' : 'Save and reload',
                  icon: PhosphorIconsRegular.arrowsClockwise,
                  busy: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: GlassPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.database, size: 16, color: Aurora.teal),
                    const SizedBox(width: 9),
                    Text('Content status', style: Aurora.body(15, weight: 600)),
                  ],
                ),
                const SizedBox(height: 12),
                DetailRow(
                  label: 'Source',
                  value: repository.isOffline ? 'Saved on device' : 'Fetched from server',
                  icon: repository.isOffline
                      ? PhosphorIconsRegular.cloudArrowDown
                      : PhosphorIconsRegular.cloudCheck,
                ),
                DetailRow(
                  label: 'Last synced',
                  value: synced == null
                      ? 'Never'
                      : DateFormat('d MMM yyyy, HH:mm').format(synced),
                  icon: PhosphorIconsRegular.clock,
                ),
                DetailRow(
                  label: 'Experiences',
                  value: '${snapshot?.allExperiences.length ?? 0}',
                  icon: PhosphorIconsRegular.briefcase,
                ),
                DetailRow(
                  label: 'Projects',
                  value: '${snapshot?.projects.length ?? 0}',
                  icon: PhosphorIconsRegular.squaresFour,
                ),
                DetailRow(
                  label: 'Content id',
                  value: (snapshot?.contentHash ?? '').isEmpty
                      ? 'unknown'
                      : snapshot!.contentHash.substring(0, 12),
                  icon: PhosphorIconsRegular.fingerprint,
                ),
                if (repository.error != null) ...[
                  const SizedBox(height: 12),
                  StatusNote(
                    tone: NoteTone.warn,
                    text: repository.error!,
                    icon: PhosphorIconsRegular.warning,
                  ),
                ],
                const SizedBox(height: 12),
                AuroraButton(
                  label: 'Refresh now',
                  icon: PhosphorIconsRegular.arrowsClockwise,
                  variant: AuroraButtonVariant.secondary,
                  busy: repository.refreshing,
                  onPressed: repository.refresh,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: GlassPanel(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.info, size: 16, color: Aurora.teal),
                    SizedBox(width: 9),
                    Text('About this app', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'The companion app to the portfolio website. It is read-only by '
                  'design: all content is served from the site\'s /api/v1 endpoints, '
                  'and the app keeps the last good copy on the device so it still '
                  'works without a connection.',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  'Both CV files, the project case studies and the direct-message '
                  'links all come from the same content the website uses.',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
