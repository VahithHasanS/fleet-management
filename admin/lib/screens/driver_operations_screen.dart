import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'shell.dart';

class DriverOperationsScreen extends StatefulWidget {
  const DriverOperationsScreen({super.key});
  @override
  State<DriverOperationsScreen> createState() => _DriverOperationsScreenState();
}

class _DriverOperationsScreenState extends State<DriverOperationsScreen> {
  String? _driverId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final driver = _driverId == null || app.drivers.isEmpty
        ? null
        : app.drivers.firstWhere((d) => d.id == _driverId);
    return PageScaffold(
      title: 'Driver Operations',
      actions: DropdownButton<String>(
        value: driver?.id,
        hint: const Text('Select driver'),
        items: app.drivers
            .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
            .toList(),
        onChanged: (id) {
          setState(() => _driverId = id);
          if (id != null) app.fetchDriverOperations(id);
        },
      ),
      child: _driverId == null
          ? const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Select a driver to review HOS logs and DVIR inspections.',
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver?.name ?? 'Driver',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recent HOS logs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                ...app.driverHos.map(
                  (log) => Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.timer,
                        color: AppColors.accentLight,
                      ),
                      title: Text(
                        log['status']
                                ?.toString()
                                .replaceAll('_', ' ')
                                .toUpperCase() ??
                            'UNKNOWN',
                      ),
                      subtitle: Text(log['startedAt']?.toString() ?? ''),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DVIR inspections',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                ...app.driverDvir.map(
                  (inspection) => Card(
                    child: ListTile(
                      leading: Icon(
                        inspection['safeToOperate'] == true
                            ? Icons.verified
                            : Icons.error,
                        color: inspection['safeToOperate'] == true
                            ? AppColors.green
                            : AppColors.red,
                      ),
                      title: Text(
                        inspection['inspectionType']
                                ?.toString()
                                .replaceAll('_', ' ')
                                .toUpperCase() ??
                            'INSPECTION',
                      ),
                      subtitle: Text(
                        inspection['submittedAt']?.toString() ?? '',
                      ),
                      trailing: Text(
                        inspection['safeToOperate'] == true ? 'SAFE' : 'UNSAFE',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
