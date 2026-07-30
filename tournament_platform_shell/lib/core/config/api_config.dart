/// Central place for backend base URLs — swap between local/staging/prod
/// via --dart-define at build time rather than hardcoding per-environment
/// files, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // 10.0.2.2 is the Android emulator's alias for the host machine's
    // localhost. iOS simulator can use 127.0.0.1 directly — override with
    // --dart-define if you're on iOS sim or a physical device on the LAN.
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String apiPrefix = '/api';

  static String get authBase => '$baseUrl$apiPrefix/auth';
  static String get apiBase => '$baseUrl$apiPrefix';

  /// ws:// for local dev; switch to wss:// for anything beyond localhost.
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://127.0.0.1:8000',
  );
}
