import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'models.dart';

enum LoadState { idle, loading, ready, error }

/// Offline-first content source.
///
/// Order of preference on launch:
///   1. the last successful snapshot from disk   (instant, works with no network)
///   2. the snapshot bundled with the APK        (first ever launch, still offline)
///   3. the network                              (refresh; updates the cache)
///
/// Refresh never blocks the UI and never clears what is already on screen: a
/// failed refresh leaves the previous snapshot in place and only sets a flag, so
/// the app can show a quiet "offline" note instead of an error page.
class PortfolioRepository extends ChangeNotifier {
  PortfolioRepository({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;

  static const _snapshotKey = 'portfolio_snapshot_v1';

  PortfolioSnapshot? _snapshot;
  PortfolioSnapshot? get snapshot => _snapshot;

  LoadState _state = LoadState.idle;
  LoadState get state => _state;

  String? _error;
  String? get error => _error;

  bool _refreshing = false;
  bool get refreshing => _refreshing;

  /// True when the content on screen came from disk or the bundled asset rather
  /// than a completed network fetch.
  bool _offline = false;
  bool get isOffline => _offline;

  DateTime? get lastSyncedAt => _snapshot?.fetchedAt;

  bool get hasContent => _snapshot != null;

  Future<void> bootstrap() async {
    _state = LoadState.loading;
    notifyListeners();

    await api.restoreBaseUrl();

    final fromDisk = await _readDisk();
    if (fromDisk != null) {
      _snapshot = fromDisk;
      _offline = true;
      _state = LoadState.ready;
      notifyListeners();
    } else {
      final bundled = await _readBundled();
      if (bundled != null) {
        _snapshot = bundled;
        _offline = true;
        _state = LoadState.ready;
        notifyListeners();
      }
    }

    await refresh();
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();

    try {
      // A hash probe first: if nothing changed, the network round trip is one
      // small request instead of five, and the cache is untouched.
      final hash = await api.fetchContentHash();
      if (hash.isNotEmpty && hash == _snapshot?.contentHash) {
        _snapshot = _snapshot == null
            ? null
            : PortfolioSnapshot(
                profile: _snapshot!.profile,
                experiences: _snapshot!.experiences,
                partTimeExperiences: _snapshot!.partTimeExperiences,
                projects: _snapshot!.projects,
                skillGroups: _snapshot!.skillGroups,
                contentHash: _snapshot!.contentHash,
                fetchedAt: DateTime.now(),
              );
        _offline = false;
        _error = null;
        _state = LoadState.ready;
        await _writeDisk(_snapshot!);
        return;
      }

      final fresh = await api.fetchSnapshot();
      _snapshot = fresh;
      _offline = false;
      _error = null;
      _state = LoadState.ready;
      await _writeDisk(fresh);
    } catch (error) {
      // Keep whatever is already rendered. Only surface the failure if there is
      // nothing to show at all.
      _offline = true;
      _error = _describe(error);
      _state = _snapshot == null ? LoadState.error : LoadState.ready;
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  /// Fetches a project's detail payload and merges it into the snapshot so the
  /// detail screen does not refetch what it already has.
  Future<Project?> loadProjectDetail(String slug) async {
    final cached = _snapshot?.projects.where((project) => project.slug == slug).firstOrNull;
    if (cached != null && cached.body.isNotEmpty) return cached;

    final detail = await api.fetchProject(slug);
    if (detail == null || _snapshot == null) return detail;

    final merged = _snapshot!.projects
        .map((project) => project.slug == slug ? detail : project)
        .toList(growable: false);

    _snapshot = PortfolioSnapshot(
      profile: _snapshot!.profile,
      experiences: _snapshot!.experiences,
      partTimeExperiences: _snapshot!.partTimeExperiences,
      projects: merged,
      skillGroups: _snapshot!.skillGroups,
      contentHash: _snapshot!.contentHash,
      fetchedAt: _snapshot!.fetchedAt,
    );
    notifyListeners();
    await _writeDisk(_snapshot!);
    return detail;
  }

  Future<void> setBaseUrl(String value) async {
    await api.setBaseUrl(value);
    // A different server means the cached snapshot belongs to someone else.
    _snapshot = null;
    await _clearDisk();
    await refresh();
  }

  // ------------------------------------------------------------------ cache --

  Future<PortfolioSnapshot?> _readDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_snapshotKey);
      if (raw == null || raw.isEmpty) return null;
      return PortfolioSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDisk(PortfolioSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_snapshotKey, jsonEncode(snapshot.toJson()));
    } catch (_) {
      // A cache write failing is not worth interrupting the user over.
    }
  }

  Future<void> _clearDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_snapshotKey);
    } catch (_) {
      // ignore
    }
  }

  /// The snapshot shipped inside the APK, so a first launch with no network
  /// still shows real content.
  Future<PortfolioSnapshot?> _readBundled() async {
    try {
      final raw = await rootBundle.loadString('assets/seed.json');
      return PortfolioSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String _describe(Object error) {
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('Connection refused')) {
      return 'Cannot reach ${api.baseUrl}';
    }
    return text.length > 200 ? '${text.substring(0, 200)}...' : text;
  }
}
