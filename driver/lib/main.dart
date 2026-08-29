import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.updateFromRuntime();
  runApp(const GhostDriverApp());
}

class GhostDriverApp extends StatelessWidget {
  const GhostDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Ghost Driver',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const LoginScreen(),
      ),
    );
  }
}
