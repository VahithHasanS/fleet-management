import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return PageScaffold(
      title: 'Fleet & Vehicles',
      scrollable: true,
      actions: OutlinedButton.icon(
        onPressed: () => _addVehicleDialog(context, app),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add vehicle'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fleets (${app.fleets.length})',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: app.fleets.isEmpty
                ? const EmptyState(message: 'No fleets yet')
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: app.fleets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final f = app.fleets[i];
                      return _FleetCard(fleet: f, app: app);
                    },
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vehicles (${app.vehicles.length})',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (app.vehicles.isEmpty)
            const EmptyState(
              message: 'No vehicles yet. Start the phantom fleet or add one.',
            )
          else
            _VehicleTable(app: app),
        ],
      ),
    );
  }

  Future<void> _addVehicleDialog(BuildContext context, AppState app) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _VehicleFormDialog(app: app),
    );
  }
}

class _FleetCard extends StatelessWidget {
  final Fleet fleet;
  final AppState app;
  const _FleetCard({required this.fleet, required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fleet.name,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fleet.city ?? '—',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const Spacer(),
          Text(
            '${fleet.vehicleCount} vehicles',
            style: const TextStyle(color: AppColors.accentLight, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _VehicleTable extends StatelessWidget {
  final AppState app;
  const _VehicleTable({required this.app});

  @override
  Widget build(BuildContext context) {
    final vehicles = app.vehicles;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(AppColors.surfaceAlt),
        columns: const [
          DataColumn(
            label: Text(
              'Name',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Plate',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Class',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Driver',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Speed',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              '',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        rows: [
          for (final v in vehicles)
            DataRow(
              cells: [
                DataCell(
                  Text(
                    v.name,
                    style: const TextStyle(color: AppColors.text, fontSize: 13),
                  ),
                ),
                DataCell(
                  Text(
                    v.plate,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    v.vehicleClass.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    v.driver?.name ?? '—',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    v.status.replaceAll('_', ' '),
                    style: TextStyle(
                      color: AppColors.statusColor(v.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${v.speedKmh.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppColors.text, fontSize: 12),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: AppColors.textMuted,
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) =>
                              _VehicleFormDialog(app: app, vehicle: v),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.red,
                        onPressed: () async {
                          final err = await app.deleteVehicle(v.id);
                          if (err != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: AppColors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _VehicleFormDialog extends StatefulWidget {
  final AppState app;
  final Vehicle? vehicle;
  const _VehicleFormDialog({required this.app, this.vehicle});

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _plate;
  late final TextEditingController _speed;
  String _class = 'car';
  String? _fleetId;
  bool _saving = false;

  bool get _isEdit => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _name = TextEditingController(text: v?.name ?? '');
    _plate = TextEditingController(text: v?.plate ?? '');
    _speed = TextEditingController(text: v?.speedLimitKmh?.toString() ?? '');
    _class = v?.vehicleClass ?? 'car';
    _fleetId = v?.fleetId;
  }

  @override
  void dispose() {
    _name.dispose();
    _plate.dispose();
    _speed.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'plate': _plate.text.trim(),
      'vehicleClass': _class,
      if (_fleetId != null) 'fleetId': _fleetId,
      if (_speed.text.isNotEmpty)
        'speedLimitKmh': int.tryParse(_speed.text) ?? 80,
    };
    final String? err;
    if (_isEdit) {
      err = await widget.app.updateVehicle(widget.vehicle!.id, body);
    } else {
      err = await widget.app.createVehicle(body);
    }
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop();
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
      title: Text(
        _isEdit ? 'Edit vehicle' : 'Add vehicle',
        style: const TextStyle(color: AppColors.text),
      ),
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
              controller: _plate,
              decoration: const InputDecoration(labelText: 'Plate'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _class,
              items: const [
                DropdownMenuItem(value: 'car', child: Text('Car')),
                DropdownMenuItem(value: 'suv', child: Text('SUV')),
                DropdownMenuItem(value: 'truck', child: Text('Truck')),
                DropdownMenuItem(value: 'bus', child: Text('Bus')),
              ],
              onChanged: (v) => setState(() => _class = v ?? 'car'),
              decoration: const InputDecoration(labelText: 'Class'),
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
            const SizedBox(height: 12),
            TextField(
              controller: _speed,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Speed limit (km/h)',
              ),
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
              : Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
