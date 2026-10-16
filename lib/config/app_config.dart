/// Compile-time configuration for the portfolio app.
class AppConfig {
  AppConfig._();

  /// Which OTA channel this build follows: `prod` or `beta`.
  static const String updateChannel = String.fromEnvironment(
    'UPDATE_CHANNEL',
    defaultValue: 'prod',
  );

  /// Base URL for raw OTA assets.
  static const String _otaBaseUrl =
      'https://raw.githubusercontent.com/ciphercall/rocket-launcher/main';

  /// Manifest this build checks for updates.
  static String get updateManifestUrl {
    const override = String.fromEnvironment('UPDATE_MANIFEST_URL');
    if (override.trim().isNotEmpty) return override.trim();
    return '$_otaBaseUrl/ota/gazi-portfolio/manifest.json';
  }

  /// Set `--dart-define=UPDATE_CHECK_ENABLED=false` to disable OTA checks (dev).
  static const bool updateCheckEnabled = bool.fromEnvironment(
    'UPDATE_CHECK_ENABLED',
    defaultValue: true,
  );

  static const String appPackageId =
      'online.peoplesitsolution.gazi_portfolio_app';
}