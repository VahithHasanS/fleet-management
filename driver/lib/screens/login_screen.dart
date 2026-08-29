import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../state/app_state.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: AppConfig.demoEmail);
  final _password = TextEditingController(text: AppConfig.demoPassword);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await context
        .read<AppState>()
        .login(_email.text.trim(), _password.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<AppState>().error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (s.user != null) return const HomeScreen();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.navigation_rounded,
                    color: Color(0xFF2F6BFF), size: 56),
                const SizedBox(height: 12),
                const Text(
                  'Ghost Driver',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFFE8EEF9)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fleet safety & trip tracking',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8CA0BC)),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      hintText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                      hintText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: s.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: s.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Sign in',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Backend: ${AppConfig.apiUrl}\nDemo: ${AppConfig.demoEmail}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF8CA0BC), fontSize: 12, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
