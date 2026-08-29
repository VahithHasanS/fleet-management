import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return PageScaffold(
      title: 'Drivers',
      scrollable: true,
      actions: OutlinedButton.icon(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _AddDriverDialog(app: app),
        ),
        icon: const Icon(Icons.person_add_alt, size: 18),
        label: const Text('Add driver'),
      ),
      child: app.drivers.isEmpty
          ? const EmptyState(message: 'No drivers yet')
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 300).floor().clamp(
                  1,
                  4,
                );
                final per = (app.drivers.length / columns).ceil().clamp(
                  1,
                  app.drivers.length,
                );
                return Column(
                  children: [
                    for (var c = 0; c < columns; c++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            for (var r = 0; r < per; r++)
                              if (c * per + r < app.drivers.length)
                                Expanded(
                                  child: _DriverCard(
                                    app: app,
                                    driver: app.drivers[c * per + r],
                                  ),
                                ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final AppState app;
  final dynamic driver;
  const _DriverCard({required this.app, required this.driver});

  @override
  Widget build(BuildContext context) {
    final d = driver;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ScoreGauge(score: d.safetyScore, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${d.tripsCount} trips · +${d.positivePoints} pts',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddDriverDialog extends StatefulWidget {
  final AppState app;
  const _AddDriverDialog({required this.app});

  @override
  State<_AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<_AddDriverDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _fleetId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final err = await widget.app.createDriver({
      'name': _name.text.trim(),
      if (_phone.text.isNotEmpty) 'phone': _phone.text.trim(),
      if (_fleetId != null) 'fleetId': _fleetId,
    });
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add driver', style: TextStyle(color: AppColors.text)),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _fleetId,
              items: [
                for (final f in widget.app.fleets)
                  DropdownMenuItem(value: f.id, child: Text(f.name)),
              ],
              onChanged: (v) => setState(() => _fleetId = v),
              decoration: const InputDecoration(labelText: 'Fleet (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
