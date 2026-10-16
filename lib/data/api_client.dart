import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// HTTP access to the portfolio API.
///
/// The base URL is a first-class setting, not a compile-time constant: an
/// emulator reaches the host on `10.0.2.2`, a physical phone needs the machine's
/// LAN address, and a tunnel needs a public hostname. Hard-coding one of those
/// would make the app work on exactly one device.
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 20)
      ..headers = {'Accept': 'application/json'};
  }

  final Dio _dio;

  static const String defaultBaseUrl = 'http://10.0.2.2:8023';
  static const String _baseKey = 'api_base_url';

  String _baseUrl = defaultBaseUrl;
  String get baseUrl => _baseUrl;

  /// Restores a previously chosen base URL. Call before the first fetch.
  Future<void> restoreBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_baseKey);
    if (stored != null && stored.trim().isNotEmpty) {
      _baseUrl = _normalise(stored);
    }
  }

  Future<void> setBaseUrl(String value) async {
    _baseUrl = _normalise(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseKey, _baseUrl);
  }

  /// Normalises a user-supplied base URL into a canonical form.
  ///
  /// - Trims surrounding whitespace.
  /// - Strips a single (or several) trailing slash(es).
  /// - Rejects empty input by falling back to [defaultBaseUrl].
  /// - Ensures a scheme is present, prepending `http://` when neither
  ///   `http://` nor `https://` is given, so a bare host like `10.0.2.2:8023`
  ///   still resolves instead of crashing later.
  static String _normalise(String value) {
    var v = value.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    if (v.isEmpty) return defaultBaseUrl;
    if (!v.startsWith('http://') && !v.startsWith('https://')) {
      v = 'http://$v';
    }
    return v;
  }

  /// Lightweight validation used by settings UI. Does not mutate or fall back;
  /// returns `false` for anything that cannot be parsed as an http(s) URL.
  static bool isValidBaseUrl(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    final candidate = (v.startsWith('http://') || v.startsWith('https://'))
        ? v
        : 'http://$v';
    final uri = Uri.tryParse(candidate);
    if (uri == null) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    if (uri.host.isEmpty) return false;
    return true;
  }

  /// Absolute URL for a `/media/...` path returned by the API.
  String mediaUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$_baseUrl${path.startsWith('/') ? '' : '/'}$path';
  }

  String cvUrl(String kind, {bool inline = false}) =>
      '$_baseUrl/api/cv/$kind${inline ? '?inline=1' : ''}';

  Future<T> _get<T>(String path, T Function(Map<String, dynamic>) parse) async {
    final response = await _dio.get<Map<String, dynamic>>('$_baseUrl$path');
    final body = response.data;
    if (body == null) {
      throw StateError('Empty response from $path');
    }
    return parse(body);
  }

  Future<String> fetchContentHash() =>
      _get('/api/v1/meta', (json) => (json['contentHash'] as String?) ?? '');

  Future<Profile> fetchProfile() => _get(
    '/api/v1/profile',
    (json) => Profile.fromJson(
      Map<String, dynamic>.from(json['profile'] as Map? ?? const {}),
    ),
  );

  Future<({List<Experience> fullTime, List<Experience> partTime})> fetchExperiences() => _get(
    '/api/v1/experiences',
    (json) {
      List<Experience> list(String key) => ((json[key] as List?) ?? const [])
          .whereType<Map>()
          .map((raw) => Experience.fromJson(Map<String, dynamic>.from(raw)))
          .toList(growable: false);
      return (fullTime: list('fullTime'), partTime: list('partTime'));
    },
  );

  Future<List<Project>> fetchProjects() => _get(
    '/api/v1/projects',
    (json) => ((json['projects'] as List?) ?? const [])
        .whereType<Map>()
        .map((raw) => Project.fromJson(Map<String, dynamic>.from(raw)))
        .toList(growable: false),
  );

  Future<List<SkillGroup>> fetchSkills() => _get(
    '/api/v1/skills',
    (json) => ((json['groups'] as List?) ?? const [])
        .whereType<Map>()
        .map((raw) => SkillGroup.fromJson(Map<String, dynamic>.from(raw)))
        .toList(growable: false),
  );

  /// Detail payload — the only endpoint that returns the markdown body.
  Future<Project?> fetchProject(String slug) async {
    try {
      return await _get(
        '/api/v1/projects/$slug',
        (json) => Project.fromJson(
          Map<String, dynamic>.from(json['project'] as Map? ?? const {}),
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Fetches everything the app needs, in parallel, and assembles one
  /// internally-consistent snapshot.
  Future<PortfolioSnapshot> fetchSnapshot() async {
    final results = await Future.wait([
      fetchProfile(),
      fetchExperiences(),
      fetchProjects(),
      fetchSkills(),
      fetchContentHash().catchError((_) => ''),
    ]);

    final profile = results[0] as Profile;
    final experiences = results[1] as ({List<Experience> fullTime, List<Experience> partTime});
    final projects = results[2] as List<Project>;
    final skills = results[3] as List<SkillGroup>;
    final hash = results[4] as String;

    return PortfolioSnapshot(
      profile: profile,
      experiences: experiences.fullTime,
      partTimeExperiences: experiences.partTime,
      projects: projects,
      skillGroups: skills,
      contentHash: hash,
      fetchedAt: DateTime.now(),
    );
  }

  /// Downloads a CV PDF into the app's own storage and returns the file.
  /// Re-downloads only when the size differs from what is already there.
  Future<File> downloadCv(String kind, {void Function(int received, int total)? onProgress}) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/cv-$kind.pdf');

    final head = await _dio.head<void>(
      cvUrl(kind),
      options: Options(followRedirects: true, validateStatus: (status) => status != null && status < 400),
    );
    final remoteLength = int.tryParse(head.headers.value('content-length') ?? '') ?? 0;

    if (await file.exists() && remoteLength > 0 && await file.length() == remoteLength) {
      return file;
    }

    await _dio.download(
      cvUrl(kind),
      file.path,
      onReceiveProgress: onProgress,
      options: Options(validateStatus: (status) => status != null && status < 400),
    );
    return file;
  }
}
