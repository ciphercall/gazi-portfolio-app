import 'package:flutter/material.dart';

import '../theme/aurora.dart';

/// Renders the small markdown subset the project bodies actually use.
///
/// A package would be more general, but this text is authored by one person in
/// one format (`###` headings, `-` bullets, blank-line paragraphs, `**bold**`),
/// and a purpose-built renderer produces exactly the intended typography with no
/// dependency and no surprise output. Anything it does not recognise is shown as
/// a plain paragraph rather than dropped.
class RichBody extends StatelessWidget {
  const RichBody(this.markdown, {super.key});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final blocks = _parse(markdown);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  List<Widget> _parse(String source) {
    final widgets = <Widget>[];
    final lines = source.replaceAll('\r\n', '\n').split('\n');

    final paragraph = <String>[];
    final bullets = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _richText(paragraph.join(' ')),
        ),
      );
      paragraph.clear();
    }

    void flushBullets() {
      if (bullets.isEmpty) return;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final bullet in bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 8, right: 11),
                        decoration: BoxDecoration(
                          gradient: Aurora.gradient(),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(child: _richText(bullet)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
      bullets.clear();
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        flushParagraph();
        flushBullets();
        continue;
      }

      if (trimmed.startsWith('## ')) {
        flushParagraph();
        flushBullets();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(trimmed.substring(3).trim(), style: Aurora.display(19)),
          ),
        );
        continue;
      }

      if (trimmed.startsWith('### ')) {
        flushParagraph();
        flushBullets();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Text(trimmed.substring(4).trim(), style: Aurora.display(17)),
          ),
        );
        continue;
      }

      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        flushParagraph();
        bullets.add(trimmed.substring(2).trim());
        continue;
      }

      flushBullets();
      paragraph.add(trimmed);
    }

    flushParagraph();
    flushBullets();
    return widgets;
  }

  /// Handles `**bold**` and `` `code` `` inline; everything else is plain.
  Widget _richText(String text) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|`(.+?)`');
    var index = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      final bold = match.group(1);
      final code = match.group(2);
      if (bold != null) {
        spans.add(
          TextSpan(
            text: bold,
            style: Aurora.body(15, weight: 600),
          ),
        );
      } else if (code != null) {
        spans.add(
          TextSpan(
            text: code,
            style: Aurora.body(14, weight: 500, color: Aurora.cyan),
          ),
        );
      }
      index = match.end;
    }

    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }

    return Text.rich(
      TextSpan(children: spans, style: Aurora.body(15, color: Aurora.muted)),
    );
  }
}
