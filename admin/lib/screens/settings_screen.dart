import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/kpi_card.dart';
import 'shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _notificationsEnabled = true;
  bool _autoRefresh = true;
  String _selectedUnits = 'Metric (km, L, °C)';
  String _selectedTimezone = 'Asia/Kolkata (IST)';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return PageScaffold(
      title: 'Settings',
      subtitle: 'Manage system configurations, users, compliance parameters, and view audit trails',
      actions: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'General'),
          Tab(text: 'Users & Roles'),
          Tab(text: 'Vehicles & Devices'),
          Tab(text: 'Alerts & Notifications'),
          Tab(text: 'Integrations'),
          Tab(text: 'Billing'),
          Tab(text: 'Audit Logs'),
        ],
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(app),
          _buildUsersTab(app),
          _buildVehiclesTab(app),
          _buildAlertsTab(),
          _buildIntegrationsTab(),
          _buildBillingTab(),
          _buildAuditLogsTab(),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(AppState app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Company Information',
            child: Column(
              children: [
                _buildTextField('Company Name', 'FleetSafe Industries Coimbatore'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Support Email', 'ops@fleetsafe.in')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Phone Number', '+91 98765 43210')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'System Preferences',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Real-time Alerts & Notifications', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Receive immediate browser/desktop alerts for critical safety violations', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  value: _notificationsEnabled,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                  activeColor: AppColors.accent,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Auto-Refresh Dashboard', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Automatically pull latest API telemetry every 10 seconds', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  value: _autoRefresh,
                  onChanged: (val) => setState(() => _autoRefresh = val),
                  activeColor: AppColors.accent,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Measurement Units', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                          Text('System-wide unit configuration for speed, mileage, and volume', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                      DropdownButton<String>(
                        value: _selectedUnits,
                        items: ['Metric (km, L, °C)', 'Imperial (mi, gal, °F)'].map((String val) {
                          return DropdownMenuItem<String>(value: val, child: Text(val));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedUnits = val!),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('System Timezone', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                          Text('Timestamp display base for all reporting databases', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                      DropdownButton<String>(
                        value: _selectedTimezone,
                        items: ['Asia/Kolkata (IST)', 'UTC (GMT)', 'America/New_York (EST)'].map((String val) {
                          return DropdownMenuItem<String>(value: val, child: Text(val));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedTimezone = val!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () {}, child: const Text('Save Settings')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildUsersTab(AppState app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SectionCard(
        title: 'Authorized Users & Access Control',
        trailing: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Invite User'),
        ),
        child: Column(
          children: [
            _buildUserRow('Manager User', 'manager@ghost.local', 'Fleet Manager', AppColors.green),
            const Divider(),
            _buildUserRow('Admin User', 'admin@ghost.local', 'Super Admin', AppColors.violet),
            const Divider(),
            _buildUserRow('Arun Kumar', 'driver@ghost.local', 'Driver', AppColors.accent),
            const Divider(),
            _buildUserRow('Dispatcher One', 'dispatch@ghost.local', 'Dispatcher', AppColors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRow(String name, String email, String role, Color roleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withOpacity(0.1),
            child: Text(name.substring(0, 1).toUpperCase(), style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: roleColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(role, style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit, size: 18, color: AppColors.textMuted)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.delete, size: 18, color: AppColors.red)),
        ],
      ),
    );
  }

  Widget _buildVehiclesTab(AppState app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SectionCard(
        title: 'Configured Fleet Vehicles',
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: app.vehicles.take(5).length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, idx) {
            final v = app.vehicles[idx];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, color: AppColors.accent, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Plate: ${v.plate} · Limit: ${v.speedLimitKmh ?? 80} km/h', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(v.status.toUpperCase(), style: TextStyle(color: AppColors.statusColor(v.status), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    return const SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: EmptyState(message: 'Alert configuration settings are active. Default triggers set to critical events.'),
      ),
    );
  }

  Widget _buildIntegrationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildIntegrationCard('SAP ERP Connector', 'Synchronize DVIR, mileage and maintenance costs', 'Connected', AppColors.green),
          const SizedBox(height: 16),
          _buildIntegrationCard('Geotab Hardware Bridge', 'Direct OBD-II hardware diagnostic telemetry intake', 'Configure', AppColors.accent),
          const SizedBox(height: 16),
          _buildIntegrationCard('AWS S3 Cold Storage', 'Archive legacy safety video attachments and GPS raw tracks', 'Connected', AppColors.green),
        ],
      ),
    );
  }

  Widget _buildIntegrationCard(String title, String desc, String status, Color statusColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.extension, color: AppColors.violet, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: () {},
              child: Text(status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingTab() {
    return const SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: EmptyState(message: 'Billing profile active. Tier: Fleet Premium Plus (50 active vehicles).'),
      ),
    );
  }

  Widget _buildAuditLogsTab() {
    final logs = [
      ('2026-08-28 19:22', 'manager@ghost.local', 'Vehicle Update', 'Modified GT 02 Speed Limit to 90km/h', 'Success'),
      ('2026-08-28 18:45', 'admin@ghost.local', 'Auth Action', 'Created new Dispatcher role key', 'Success'),
      ('2026-08-28 17:12', 'manager@ghost.local', 'Simulator Command', 'Started Phantom Fleet simulation sequence', 'Success'),
      ('2026-08-28 15:30', 'system_bot', 'Compliance Run', 'Generated DVIR report for ELD submit', 'Success'),
      ('2026-08-28 14:02', 'admin@ghost.local', 'Security Audit', 'Updated JWT rotation policy settings', 'Success'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SectionCard(
        title: 'System Activity Logs & Auditing Trail',
        trailing: Row(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.filter_alt, size: 18, color: AppColors.textMuted)),
            const SizedBox(width: 8),
            TextButton(onPressed: () {}, child: const Text('Export PDF')),
          ],
        ),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(5),
            4: FlexColumnWidth(2),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              children: [
                Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Timestamp', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Actor', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Module', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Action details', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Status', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
            ...logs.map((log) => TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
              children: [
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(log.$1, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(log.$2, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(log.$3, style: const TextStyle(color: AppColors.text, fontSize: 13))),
                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(log.$4, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(log.$5, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
