import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'ghost_api_url.dart';
import 'screens/login_screen.dart';
import 'screens/shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // On web, reads `window.ghostApiUrl` (set in web/index.html) if present.
    // On other platforms this is a no-op stub.
    updateFromWindowGhostApiUrl(AppConfig.updateFromJs);
  } catch (_) {
    // Ignore — fall back to the dart-define / default URL.
  }
  runApp(const GhostAdminApp());
}

class GhostAdminApp extends StatelessWidget {
  const GhostAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Ghost Telemetry — Fleet Operations',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return app.user == null ? const LoginScreen() : const Shell();
  }
}
