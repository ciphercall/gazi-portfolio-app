import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gazi_portfolio_app/models/app_update_manifest.dart';
import 'package:gazi_portfolio_app/services/app_update_service.dart';
import 'package:gazi_portfolio_app/widgets/update_gate.dart';

AppUpdateManifest _manifest() => AppUpdateManifest.fromJson({
      'app_id': 'gazi-portfolio',
      'version_name': '0.3.4',
      'version_code': 107,
      'force_update': true,
      'release_notes': 'Layout refresh and the living background.',
      'apks': {
        'arm64-v8a': {
          'url': 'https://example.com/gazi-arm64.apk',
          'size_bytes': 1000,
          'sha256': 'abc',
        },
      },
    });

void main() {
  testWidgets('a forced update renders inside its own MaterialApp', (
    tester,
  ) async {
    await tester.pumpWidget(
      UpdateGate(
        initialResult: AppUpdateCheckResult.updateRequired(
          manifest: _manifest(),
          installedVersionCode: 106,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Update required'), findsOneWidget);
    expect(find.textContaining('build 106'), findsOneWidget);
    expect(find.text('Download update'), findsOneWidget);
  });
}
