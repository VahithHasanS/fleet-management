import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class DvirScreen extends StatefulWidget {
  const DvirScreen({super.key});
  @override
  State<DvirScreen> createState() => _DvirScreenState();
}

class _DvirScreenState extends State<DvirScreen> {
  final List<Map<String, dynamic>> _checklist = [
    {'name': 'Brakes & Air Lines', 'checked': true},
    {'name': 'Tires & Wheels', 'checked': true},
    {'name': 'Lights & Reflectors', 'checked': true},
    {'name': 'Mirrors & Windshield', 'checked': true},
    {'name': 'Engine Fluids & Belts', 'checked': true},
    {'name': 'Steering & Suspension', 'checked': true},
  ];

  final _defectController = TextEditingController();
  String _selectedSeverity = 'medium';
  bool _safeToOperate = true;
  bool _saving = false;
  String? _photoPath;

  @override
  void dispose() {
    _defectController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() => _photoPath = photo.path);
    }
  }

  Future<void> _submit() async {
    final s = context.read<AppState>();
    if (s.myVehicle == null) return;
    setState(() => _saving = true);

    final itemsList = _checklist.map((c) => {
      'name': c['name'] as String,
      'status': (c['checked'] as bool) ? 'ok' : 'defect',
    }).toList();

    if (_defectController.text.isNotEmpty) {
      itemsList.add({
        'name': 'Custom Defect Log',
        'status': 'defect',
        'detail': _defectController.text.trim(),
        'severity': _selectedSeverity,
        if (_photoPath != null) 'photoPath': _photoPath!,
      });
    }

    final error = await s.submitDvir(
      inspectionType: 'pre_trip',
      safeToOperate: _safeToOperate,
      items: itemsList,
    );

    if (mounted) {
      setState(() => _saving = false);
      if (error == null) {
        _defectController.clear();
        setState(() {
          _photoPath = null;
          for (var item in _checklist) {
            item['checked'] = true;
          }
          _safeToOperate = true;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'DVIR inspection submitted successfully'),
          backgroundColor: error == null ? AppColors.green : AppColors.red,
        ),
      );
    }
  }

  void _showChangeVehicleDialog(AppState s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Select Assigned Vehicle', style: TextStyle(color: AppColors.text)),
        content: SizedBox(
          width: 320,
          child: s.vehicles.isEmpty
              ? const Text('No vehicles available in system.', style: TextStyle(color: AppColors.textMuted))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: s.vehicles.length,
                  itemBuilder: (context, index) {
                    final v = s.vehicles[index];
                    final isCurrent = s.myVehicle?.id == v.id;
                    return ListTile(
                      title: Text(v.name, style: TextStyle(color: isCurrent ? AppColors.accent : AppColors.text)),
                      subtitle: Text(v.plate, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      trailing: isCurrent ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                      onTap: () {
                        s.setMyVehicle(v);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DVIR Inspection'),
        actions: [
          IconButton(
            onPressed: s.refreshOperations,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Inspections',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Vehicle Selector / Info ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping, color: AppColors.accent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ACTIVE ASSIGNED VEHICLE', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        s.myVehicle == null ? 'No Assigned Vehicle Found' : '${s.myVehicle!.name} · ${s.myVehicle!.plate}',
                        style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showChangeVehicleDialog(s),
                  child: const Text('Change', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Pre-Trip Header & Checklist ──
          const Text('PRE-TRIP CHECKLIST', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Verify each component is in safe operating condition:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: _checklist.map((c) {
                final checked = c['checked'] as bool;
                return CheckboxListTile(
                  title: Text(c['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  value: checked,
                  activeColor: AppColors.green,
                  onChanged: (val) {
                    setState(() {
                      c['checked'] = val;
                      if (val == false) {
                        _safeToOperate = false;
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Defect Section ──
          const Text('REPORT DEFECTS (OPTIONAL)', style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _defectController,
            maxLines: 2,
            style: const TextStyle(fontSize: 14, color: AppColors.text),
            decoration: const InputDecoration(
              hintText: 'Describe defect details (e.g. left tail light bulb cracked)',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSeverity,
                  decoration: const InputDecoration(
                    labelText: 'Defect Severity',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low Severity', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'medium', child: Text('Medium Severity', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'high', child: Text('High Severity', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'critical', child: Text('Critical Hazard', style: TextStyle(fontSize: 13))),
                  ],
                  onChanged: (val) => setState(() => _selectedSeverity = val!),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: Icon(_photoPath != null ? Icons.check : Icons.camera_alt, size: 18),
                label: Text(_photoPath != null ? 'Attached' : 'Add Photo', style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          if (_photoPath != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attachment, color: AppColors.green, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text(_photoPath!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
                IconButton(
                  onPressed: () => setState(() => _photoPath = null),
                  icon: const Icon(Icons.close, size: 14, color: AppColors.red),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // ── Safe To Operate Toggle ──
          SwitchListTile(
            value: _safeToOperate,
            activeColor: AppColors.green,
            onChanged: (val) => setState(() => _safeToOperate = val),
            title: const Text('Vehicle Safe to Operate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: const Text('Certify that vehicle is safe for road dispatch duty', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ),
          const SizedBox(height: 12),

          // ── Submit Button ──
          ElevatedButton.icon(
            onPressed: _saving || s.myVehicle == null ? null : _submit,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_outlined),
            label: Text(_saving ? 'Submitting...' : 'Submit Inspection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 24),

          // ── Recent Inspections ──
          const Text('RECENT SUBMITTED INSPECTIONS', style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (s.inspections.isEmpty)
            const Center(child: Text('No historical inspections logged.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)))
          else
            ...s.inspections.take(5).map((i) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    i.safeToOperate ? Icons.check_circle : Icons.warning,
                    color: i.safeToOperate ? AppColors.green : AppColors.red,
                  ),
                  title: Text(i.inspectionType.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(i.submittedAt.toLocal().toString().substring(0, 19), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  trailing: Text(i.safeToOperate ? 'PASS' : 'FAIL', style: TextStyle(color: i.safeToOperate ? AppColors.green : AppColors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              );
            }),
        ],
      ),
    );
  }
}
