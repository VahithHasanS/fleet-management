/// App-level configuration.
///
/// The backend URL can be overridden at build time with
/// `flutter build web --dart-define=API_URL=http://host:3000`, otherwise it
/// defaults to the local dev backend. A `window.ghostApiUrl` override set in
/// `web/index.html` takes precedence so the demo can be pointed at a remote
/// deployment without a rebuild.

class AppConfig {
  AppConfig._();

  static const String _builtIn = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static String backendUrl = _builtIn;

  static void updateFromJs(String? override) {
    if (override != null && override.isNotEmpty) {
      backendUrl = override.replaceAll(RegExp(r'/$'), '');
    }
  }

  /// WebSocket endpoint derived from the HTTP backend origin.
  static String get wsUrl {
    final u = Uri.parse(backendUrl);
    final scheme = u.scheme == 'https' ? 'wss' : 'ws';
    final port = u.hasPort ? ':${u.port}' : '';
    return '$scheme://${u.host}$port/ws';
  }

  static String tenantBase(String? tenantId) => '/api/v1/tenants/$tenantId';
}
