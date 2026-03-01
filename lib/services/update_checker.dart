import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

const String _pubspecRawUrl =
    'https://raw.githubusercontent.com/ramdanolii14/myokane/main/pubspec.yaml';
const String _releasesUrl = 'https://github.com/ramdanolii14/myokane/releases';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool hasUpdate;
  final bool isError;
  final String? errorMessage;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    this.isError = false,
    this.errorMessage,
  });

  factory UpdateInfo.error(String msg, {required String currentVersion}) =>
      UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        hasUpdate: false,
        isError: true,
        errorMessage: msg,
      );

  factory UpdateInfo.upToDate({required String currentVersion}) => UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        hasUpdate: false,
      );
}

class UpdateChecker {
  // Cache agar PackageInfo.fromPlatform() hanya dipanggil sekali
  static PackageInfo? _cachedInfo;

  static Future<PackageInfo> _getPackageInfo() async {
    _cachedInfo ??= await PackageInfo.fromPlatform();
    return _cachedInfo!;
  }

  /// Versi lokal saat ini — dibaca dari pubspec.yaml via package_info_plus
  static Future<String> get currentVersion async {
    final info = await _getPackageInfo();
    return info.version;
  }

  static Future<UpdateInfo> check() async {
    final localVersion = await currentVersion;

    try {
      final response = await http
          .get(Uri.parse(_pubspecRawUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return UpdateInfo.error(
          'Server returned ${response.statusCode}',
          currentVersion: localVersion,
        );
      }

      final version = _parseVersion(response.body);
      if (version == null) {
        return UpdateInfo.error(
          'Gagal membaca versi dari pubspec.yaml',
          currentVersion: localVersion,
        );
      }

      final hasUpdate = _isNewer(version, localVersion);

      return UpdateInfo(
        currentVersion: localVersion,
        latestVersion: version,
        hasUpdate: hasUpdate,
      );
    } on SocketException {
      return UpdateInfo.error(
        'Tidak ada koneksi internet',
        currentVersion: localVersion,
      );
    } catch (e) {
      return UpdateInfo.error(
        'Gagal mengecek update',
        currentVersion: localVersion,
      );
    }
  }

  /// Parse `version: x.y.z+build` dari isi pubspec.yaml
  static String? _parseVersion(String content) {
    final regExp = RegExp(r'^version:\s*(\d+\.\d+\.\d+)', multiLine: true);
    final match = regExp.firstMatch(content);
    return match?.group(1);
  }

  /// Bandingkan apakah [remote] lebih baru dari [local]
  static bool _isNewer(String remote, String local) {
    final r = _toInts(remote);
    final l = _toInts(local);
    for (int i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }

  static List<int> _toInts(String v) {
    final parts = v.split('.');
    return List.generate(3, (i) => int.tryParse(parts[i]) ?? 0);
  }

  static String get releasesUrl => _releasesUrl;
}
