import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'manager@ghost.local');
  final _password = TextEditingController(text: 'ghost123');
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final app = context.read<AppState>();
    FocusScope.of(context).unfocus();
    final ok = await app.login(_email.text.trim(), _password.text);
    if (!ok && mounted) {
      final msg = app.error ?? 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.red),
      );
    }
  }

  void _quickFill(String email, String password) {
    _email.text = email;
    _password.text = password;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.accent, AppColors.violet]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.gps_fixed, color: Colors.white, size: 34),
                ),
                const SizedBox(height: 18),
                const Text('Ghost Telemetry',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.text, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Fleet Management & Driver Safety',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                const SizedBox(height: 32),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                      labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: app.busy ? null : _login,
                  child: app.busy
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 20),
                const Text('Demo accounts',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                _DemoRow(
                  label: 'Fleet Manager',
                  email: 'manager@ghost.local',
                  onTap: () => _quickFill('manager@ghost.local', 'ghost123'),
                ),
                _DemoRow(
                  label: 'Dispatcher',
                  email: 'dispatch@ghost.local',
                  onTap: () => _quickFill('dispatch@ghost.local', 'ghost123'),
                ),
                _DemoRow(
                  label: 'Super Admin',
                  email: 'superadmin@ghost.local',
                  onTap: () => _quickFill('superadmin@ghost.local', 'ghost123'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoRow extends StatelessWidget {
  final String label;
  final String email;
  final VoidCallback onTap;
  const _DemoRow({required this.label, required this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('$label  ·  $email',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
            const Icon(Icons.add_circle_outline, color: AppColors.accent, size: 16),
          ],
        ),
      ),
    );
  }
}
