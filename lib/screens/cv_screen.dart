import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/repository.dart';
import '../theme/aurora.dart';
import '../widgets/buttons.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';

class CvScreen extends StatelessWidget {
  const CvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<PortfolioRepository>();

    return ContentGate(
      repository: repository,
      builder: (context) {
        final profile = repository.snapshot!.profile;

        return ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 22, 18, 0),
              child: SectionHeading(
                eyebrow: 'Curriculum vitae',
                eyebrowIcon: PhosphorIconsRegular.filePdf,
                title: 'Two versions, on purpose',
                lead: 'The same content, built for two different readers. Take whichever the situation calls for.',
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Text(
                profile.summary,
                style: Aurora.body(14, color: Aurora.muted),
              ),
            ),
            const SizedBox(height: 20),
            OfflineNote(repository: repository),

            _VariantPanel(
              kind: 'designed',
              title: 'Designed / colorized',
              icon: PhosphorIconsRegular.paintBrushBroad,
              description:
                  'The portfolio itself, printed to A4: the same colours, layout and typography you see on the site. This is the version to send when a person will read it.',
              points: const [
                'Aurora palette and custom layout',
                'Reads as a designed document',
                'Use for direct applications and introductions',
              ],
            ),
            const SizedBox(height: 16),
            _VariantPanel(
              kind: 'ats',
              title: 'ATS-friendly',
              icon: PhosphorIconsRegular.robot,
              description:
                  'Deliberately plain, so applicant-tracking software can parse it reliably. Its beauty is that a machine can read every line.',
              points: const [
                'Single column, no images, no tables',
                'Standard fonts and conventional headings',
                'Month-and-year dates, one fact per line',
              ],
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: StatusNote(
                tone: NoteTone.ok,
                icon: PhosphorIconsRegular.arrowsClockwise,
                text: 'Both files are generated from the same live content as the '
                    'website, so a download is never out of date.',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VariantPanel extends StatefulWidget {
  const _VariantPanel({
    required this.kind,
    required this.title,
    required this.icon,
    required this.description,
    required this.points,
  });

  final String kind;
  final String title;
  final IconData icon;
  final String description;
  final List<String> points;

  @override
  State<_VariantPanel> createState() => _VariantPanelState();
}

class _VariantPanelState extends State<_VariantPanel> {
  bool _busy = false;
  String? _error;

  Future<File?> _fetch() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = context.read<PortfolioRepository>().api;
      return await api.downloadCv(widget.kind);
    } catch (error) {
      if (mounted) setState(() => _error = _describe(error));
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _describe(Object error) {
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('Connection')) {
      return 'Could not reach the server. Is the stack running?';
    }
    return 'The download failed. Try again, or check Settings for the server address.';
  }

  Future<void> _open() async {
    final file = await _fetch();
    if (file == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _PdfViewer(file: file, title: widget.title)),
    );
  }

  Future<void> _share() async {
    final file = await _fetch();
    if (file == null || !mounted) return;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: widget.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GlassPanel(
        gradientEdge: widget.kind == 'designed',
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Aurora.teal.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(Aurora.radiusControl),
                  ),
                  child: Icon(widget.icon, size: 18, color: Aurora.teal),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.title, style: Aurora.display(18))),
              ],
            ),
            const SizedBox(height: 12),
            Text(widget.description, style: Aurora.body(13.5, color: Aurora.muted)),
            const SizedBox(height: 14),
            for (final point in widget.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 8, right: 10),
                      decoration: BoxDecoration(
                        gradient: Aurora.gradient(),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(child: Text(point, style: Aurora.body(13, color: Aurora.faint))),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              StatusNote(tone: NoteTone.warn, text: _error!, icon: PhosphorIconsRegular.warning),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                AuroraButton(
                  label: _busy ? 'Preparing' : 'Open',
                  icon: PhosphorIconsRegular.eye,
                  busy: _busy,
                  onPressed: _busy ? null : _open,
                ),
                AuroraButton(
                  label: 'Share file',
                  icon: PhosphorIconsRegular.shareNetwork,
                  variant: AuroraButtonVariant.secondary,
                  onPressed: _busy ? null : _share,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen PDF preview with the close control OUTSIDE the document area, so
/// it cannot be pushed out of reach by a long file.
class _PdfViewer extends StatefulWidget {
  const _PdfViewer({required this.file, required this.title});

  final File file;
  final String title;

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  int _pages = 0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Aurora.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: Aurora.display(15)),
                        if (_pages > 0)
                          Text('$_pages pages', style: Aurora.label()),
                      ],
                    ),
                  ),
                  AuroraButton(
                    label: 'Close',
                    icon: PhosphorIconsRegular.x,
                    variant: AuroraButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: StatusNote(
                          tone: NoteTone.warn,
                          text: _error!,
                          icon: PhosphorIconsRegular.warning,
                        ),
                      ),
                    )
                  : PDFView(
                      filePath: widget.file.path,
                      backgroundColor: Aurora.canvas,
                      onRender: (pages) => setState(() => _pages = pages ?? 0),
                      onError: (error) => setState(() => _error = '$error'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
