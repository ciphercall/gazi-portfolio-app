import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../main.dart' show GaziPortfolioApp;
import '../screens/app_update_screen.dart';
import '../services/app_update_service.dart';

/// Checks GitHub OTA manifest on cold start and swaps in the update screen when
/// a newer build is required. Otherwise returns the app root.
class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key});

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  final AppUpdateService _updateService = AppUpdateService();
  AppUpdateCheckResult? _result;

  @override
  void initState() {
    super.initState();

    if (!AppConfig.updateCheckEnabled) {
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
      return AppUpdateScreen(
        manifest: result.manifest!,
        installedVersionCode: result.installedVersionCode,
      );
    }

    return const GaziPortfolioApp();
  }
}