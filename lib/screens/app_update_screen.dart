import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/app_update_manifest.dart';
import '../services/app_update_service.dart';
import '../theme/aurora.dart';
import '../widgets/buttons.dart';

enum AppUpdateUiPhase {
  ready,
  downloading,
  verifying,
  installing,
  error,
}

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({
    super.key,
    required this.manifest,
    required this.installedVersionCode,
  });

  final AppUpdateManifest manifest;
  final int installedVersionCode;

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  final AppUpdateService _service = AppUpdateService();

  AppUpdateUiPhase _phase = AppUpdateUiPhase.ready;
  String? _errorMessage;
  int _received = 0;
  int _total = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Aurora.canvas,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        PhosphorIconsRegular.downloadSimple,
                        size: 56,
                        color: Aurora.teal,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Update required',
                        textAlign: TextAlign.center,
                        style: Aurora.display(22, weight: 700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'v${widget.manifest.versionName} (build ${widget.manifest.versionCode}) is available.\n'
                        'You are on build ${widget.installedVersionCode}.',
                        textAlign: TextAlign.center,
                        style: Aurora.body(13, color: Aurora.muted, weight: 500),
                      ),
                      if (widget.manifest.channel == 'beta') ...[
                        const SizedBox(height: 10),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Aurora.rose.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(Aurora.radiusPill),
                            ),
                            child: Text(
                              'Beta build — beta testers only',
                              textAlign: TextAlign.center,
                              style: Aurora.body(
                                11,
                                weight: 600,
                                color: Aurora.rose,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (widget.manifest.releaseNotes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: Aurora.glass(),
                          child: Text(
                            widget.manifest.releaseNotes,
                            style: Aurora.body(13, color: Aurora.ink),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _buildActionArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_phase == AppUpdateUiPhase.downloading) ...[
            LinearProgressIndicator(
              value: _total > 0 ? _received / _total : null,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: Aurora.teal,
              backgroundColor: Aurora.panelStrong,
            ),
            const SizedBox(height: 12),
            Text(
              '${formatBytes(_received)} / ${formatBytes(_total)}  (${downloadPercent(_received, _total)}%)',
              textAlign: TextAlign.center,
              style: Aurora.body(13, weight: 600),
            ),
            const SizedBox(height: 8),
            Text(
              'Downloading update…',
              textAlign: TextAlign.center,
              style: Aurora.body(12, color: Aurora.muted),
            ),
          ] else if (_phase == AppUpdateUiPhase.verifying) ...[
            const Center(
              child: CircularProgressIndicator(color: Aurora.teal),
            ),
            const SizedBox(height: 12),
            Text(
              'Verifying download…',
              textAlign: TextAlign.center,
              style: Aurora.body(13),
            ),
          ] else if (_phase == AppUpdateUiPhase.installing) ...[
            const Center(
              child: CircularProgressIndicator(color: Aurora.teal),
            ),
            const SizedBox(height: 12),
            Text(
              'Opening installer…\nTap Install on the system dialog.',
              textAlign: TextAlign.center,
              style: Aurora.body(13),
            ),
          ] else if (_phase == AppUpdateUiPhase.error) ...[
            Text(
              _errorMessage ?? 'Update failed.',
              textAlign: TextAlign.center,
              style: Aurora.body(13, color: Aurora.rose),
            ),
            const SizedBox(height: 16),
            AuroraButton(
              label: 'Retry download',
              icon: PhosphorIconsRegular.arrowsClockwise,
              onPressed: _startDownload,
              expand: true,
            ),
          ] else ...[
            AuroraButton(
              label: 'Download update',
              icon: PhosphorIconsRegular.downloadSimple,
              onPressed: _startDownload,
              expand: true,
            ),
          ],
          const SizedBox(height: 12),
          if (widget.manifest.forceUpdate)
            Text(
              'You must install this update to continue using the app.',
              textAlign: TextAlign.center,
              style: Aurora.body(11, color: Aurora.muted),
            ),
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    if (!Platform.isAndroid) {
      setState(() {
        _phase = AppUpdateUiPhase.error;
        _errorMessage = 'Updates are only supported on Android.';
      });
      return;
    }

    setState(() {
      _phase = AppUpdateUiPhase.downloading;
      _errorMessage = null;
      _received = 0;
      _total = widget.manifest.resolveApk(
            preferredAbi: 'arm64-v8a',
          )?.sizeBytes ??
          0;
    });

    try {
      final file = await _service.downloadApk(
        manifest: widget.manifest,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            _total = total;
          });
        },
      );

      if (!mounted) return;
      setState(() => _phase = AppUpdateUiPhase.installing);

      await _service.installApk(file);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = AppUpdateUiPhase.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }
}