import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../main.dart' show GaziPortfolioApp;
import '../screens/app_update_screen.dart';
import '../services/app_update_service.dart';
import '../theme/aurora.dart';

/// Checks GitHub OTA manifest on cold start and swaps in the update screen when
/// a newer build is required. Otherwise returns the app root.
class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, this.service, this.initialResult});

  /// Injectable for widget tests; production always builds the real service.
  final AppUpdateService? service;

  /// Test-only shortcut: skips the network check and renders this result on the
  /// first frame.
  final AppUpdateCheckResult? initialResult;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  late final AppUpdateService _updateService =
      widget.service ?? AppUpdateService();
  late AppUpdateCheckResult? _result = widget.initialResult;

  @override
  void initState() {
    super.initState();

    if (!AppConfig.updateCheckEnabled || widget.initialResult != null) {
      return;
    }

    unawaited(_check());
  }

  Future<void> _check() async {
    try {
      final result = await _updateService.checkForUpdate();
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      debugPrint('Update check failed, continuing without it: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.updateCheckEnabled) {
      return const GaziPortfolioApp();
    }

    final result = _result;
    if (result == null) {
      return const GaziPortfolioApp();
    }

    if (result.needsUpdate && result.manifest != null) {
      // The gate sits above the router's MaterialApp, so the update screen must
      // bring its own. Without this, Scaffold has no MediaQuery/Directionality
      // and the release build shows an empty grey window instead of the prompt.
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAuroraTheme(),
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
          child: child ?? const SizedBox.shrink(),
        ),
        home: AppUpdateScreen(
          manifest: result.manifest!,
          installedVersionCode: result.installedVersionCode,
        ),
      );
    }

    return const GaziPortfolioApp();
  }
}