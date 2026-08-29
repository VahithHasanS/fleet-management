/// Runtime + build-time configuration for the driver app.
///
/// Precedence: `window.ghostApiUrl` (runtime override, set in web/index.html)
/// > `--dart-define=API_URL=...` (build time) > localhost default.
library;

import 'package:flutter/foundation.dart';

import 'config_stub.dart'
    if (dart.library.js_interop) 'config_web.dart'
    as runtime_config;

class AppConfig {
  static const String defaultApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.23.216:3000',
  );

  static String apiUrl = defaultApiUrl;

  static void updateFromRuntime() {
    if (!kIsWeb) return;
    final override = runtime_config.ghostApiUrl;
    if (override != null && override.isNotEmpty) {
      apiUrl = override.replaceAll(RegExp(r'/$'), '');
    }
  }

  /// Socket.io namespace path on the backend.
  static const String wsPath = '/ws';

  /// Demo credentials shown on the login screen.
  static const String demoEmail = 'driver@ghost.local';
  static const String demoPassword = 'ghost123';
}
