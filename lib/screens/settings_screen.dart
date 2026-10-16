import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/repository.dart';
import '../screens/app_update_screen.dart';
import '../services/app_update_service.dart';
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
  String? _error;

  bool _checkingUpdate = false;
  String? _updateStatus;
  AppUpdateCheckResult? _updateResult;

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
    if (!ApiClient.isValidBaseUrl(_controller.text)) {
      setState(() => _error = 'Please enter a valid http:// or https:// URL, including the port.');
      return;
    }
    final repository = context.read<PortfolioRepository>();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await repository.setBaseUrl(_controller.text);
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _checkForUpdate() async {
    if (_checkingUpdate) return;
    setState(() {
      _checkingUpdate = true;
      _updateStatus = null;
      _updateResult = null;
    });
    try {
      final result = await AppUpdateService().checkForUpdate();
      if (!mounted) return;
      setState(() {
        _updateResult = result;
        if (result.needsUpdate && result.manifest != null) {
          _updateStatus =
              'Update available: v${result.manifest!.versionName} '
              '(build ${result.manifest!.versionCode}).';
        } else if (result.hasError) {
          _updateStatus = result.errorMessage;
        } else {
          _updateStatus = 'You are up to date.';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _updateStatus = e.toString());
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  void _openUpdateScreen() {
    final result = _updateResult;
    if (result == null || !result.needsUpdate || result.manifest == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AppUpdateScreen(
          manifest: result.manifest!,
          installedVersionCode: result.installedVersionCode,
        ),
      ),
    );
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
                if (_error != null) ...[
                  Text(_error!, style: Aurora.body(12.5, color: Aurora.rose)),
                  const SizedBox(height: 8),
                ],
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

        Padding(
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
                    Text('About this app', style: Aurora.body(15, weight: 600, color: Aurora.ink)),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'The companion app to the portfolio website. It is read-only by '
                  'design: all content is served from the site\'s /api/v1 endpoints, '
                  'and the app keeps the last good copy on the device so it still '
                  'works without a connection.',
                  style: Aurora.body(13, color: Aurora.muted),
                ),
                SizedBox(height: 10),
                Text(
                  'Both CV files, the project case studies and the direct-message '
                  'links all come from the same content the website uses.',
                  style: Aurora.body(13, color: Aurora.muted),
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
                    const Icon(PhosphorIconsRegular.arrowCircleDown,
                        size: 16, color: Aurora.teal),
                    const SizedBox(width: 9),
                    Text('Updates', style: Aurora.body(15, weight: 600, color: Aurora.ink)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Check GitHub for a newer build of this app. Updates are '
                  'downloaded and installed on-device.',
                  style: Aurora.body(13, color: Aurora.muted),
                ),
                if (_updateStatus != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _updateStatus!,
                    style: Aurora.body(
                      12.5,
                      color: (_updateResult?.hasError ?? false)
                          ? Aurora.rose
                          : Aurora.teal,
                      weight: 500,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                AuroraButton(
                  label: _checkingUpdate ? 'Checking' : 'Check for update',
                  icon: PhosphorIconsRegular.arrowsClockwise,
                  busy: _checkingUpdate,
                  onPressed: _checkingUpdate ? null : _checkForUpdate,
                ),
                if (_updateResult?.needsUpdate == true) ...[
                  const SizedBox(height: 10),
                  AuroraButton(
                    label: 'View update',
                    icon: PhosphorIconsRegular.downloadSimple,
                    variant: AuroraButtonVariant.secondary,
                    onPressed: _openUpdateScreen,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
