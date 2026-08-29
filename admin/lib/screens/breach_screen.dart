import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' as mdb hide State, Center, Where, QueryBuilder;

import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import 'shell.dart';

/// Breach screen that connects directly to MongoDB Atlas
/// and displays camera breach data with refresh capability.
class BreachScreen extends StatefulWidget {
  const BreachScreen({super.key});

  @override
  State<BreachScreen> createState() => _BreachScreenState();
}

class _BreachScreenState extends State<BreachScreen> {
  static const String _atlasUri =
      'mongodb+srv://Shajahan_Access_2:Howkey%402011@tpcbr-4-project.ou5hsth.mongodb.net/';

  mdb.Db? _db;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _breaches = [];
  Map<String, int> _stats = {};
  String _selectedType = 'All';
  DateTime? _lastRefreshed;

  @override
  void initState() {
    super.initState();
    _connectAndFetch();
  }

  @override
  void dispose() {
    _db?.close();
    super.dispose();
  }

  Future<void> _connectAndFetch() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _db = await mdb.Db.create(_atlasUri);
      await _db!.open();
      await _fetchBreaches();
      await _fetchStats();
      setState(() {
        _lastRefreshed = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBreaches() async {
    if (_db == null) return;
    final collection = _db!.collection('camera_breaches');
    final cursor = collection.find(mdb.where.sortBy('timestamp', descending: true).limit(500));
    final docs = await cursor.toList();

    setState(() {
      _breaches = docs.cast<Map<String, dynamic>>();
    });
  }

  Future<void> _fetchStats() async {
    if (_db == null) return;
    final collection = _db!.collection('camera_breaches');

    final total = await collection.count();

    final agg = await collection.aggregate([
      {'\$group': {'_id': '\$breachType', 'count': {'\$sum': 1}}},
    ]);
    final byType = <String, int>{};
    if (agg is List) {
      for (final doc in agg) {
        byType[doc['_id'].toString()] = (doc['count'] as int);
      }
    } else if (agg is Map) {
      final docs = agg['documents'] as List<dynamic>? ?? [];
      for (final doc in docs) {
        byType[doc['_id'].toString()] = (doc['count'] as int);
      }
    }

    final vehicleAgg = await collection.aggregate([
      {'\$group': {'_id': '\$vehicleName', 'count': {'\$sum': 1}}},
      {'\$sort': {'count': -1}},
      {'\$limit': 5},
    ]);
    final topVehicles = <String, int>{};
    if (vehicleAgg is List) {
      for (final doc in vehicleAgg) {
        topVehicles[doc['_id'].toString()] = (doc['count'] as int);
      }
    } else if (vehicleAgg is Map) {
      final docs = vehicleAgg['documents'] as List<dynamic>? ?? [];
      for (final doc in docs) {
        topVehicles[doc['_id'].toString()] = (doc['count'] as int);
      }
    }

    setState(() {
      _stats = {
        'total': total,
        ...byType,
        'topVehicles': topVehicles.length,
      };
    });
  }

  Future<void> _refresh() async {
    await _connectAndFetch();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBreaches = _selectedType == 'All'
        ? _breaches
        : _breaches.where((b) => b['breachType'] == _selectedType).toList();

    final breachTypes = ['All', ..._breaches.map((b) => b['breachType'].toString()).toSet().toList()..sort()];

    final children = <Widget>[
      // Stats Row
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: KpiCard(
                label: 'Total Breaches',
                value: '${_stats['total'] ?? _breaches.length}',
                icon: Icons.warning_amber,
                color: AppColors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Drowsiness',
                value: '${_stats['drowsiness'] ?? 0}',
                icon: Icons.bedtime,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Eye Closure',
                value: '${_stats['eye_closure'] ?? 0}',
                icon: Icons.visibility_off,
                color: AppColors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Distraction',
                value: '${_stats['distraction'] ?? 0}',
                icon: Icons.phone_android,
                color: AppColors.textMuted,
              ),
            ),
          ],
      ),
      _buildLastRefreshed(),
      _buildError(),
      // Breach List
      Expanded(
        child: _buildBreachList(),
      ),
    ];

    return PageScaffold(
      title: 'Camera AI Breaches',
      subtitle: 'Direct MongoDB Atlas data \u2014 breach events, stats, and live refresh',
      actions: Row(
        children: [
          DropdownButton<String>(
            value: _selectedType,
            items: breachTypes.map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedType = val ?? 'All'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _refresh,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh, size: 16),
            label: Text(_isLoading ? 'Refreshing...' : 'Refresh'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildLastRefreshed() {
    if (_lastRefreshed == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Last updated: ${DateFormat('HH:mm:ss').format(_lastRefreshed!)}',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
    );
  }

  Widget _buildError() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.red),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.red, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get filteredBreaches {
    if (_selectedType == 'All') return _breaches;
    return _breaches.where((b) => b['breachType'] == _selectedType).toList();
  }

  List<String> get breachTypes {
    final types = _breaches.map((b) => b['breachType'].toString()).toSet().toList();
    types.sort();
    return ['All', ...types];
  }

  Widget _buildBreachList() {
    final filteredBreaches = _selectedType == 'All'
        ? _breaches
        : _breaches.where((b) => b['breachType'] == _selectedType).toList();

    if (filteredBreaches.isEmpty) {
      return const Center(
        child: Text(
          'No breaches found',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: filteredBreaches.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _BreachTile(
        breach: filteredBreaches[i],
      ),
    );
  }
}

class _BreachTile extends StatelessWidget {
  final Map<String, dynamic> breach;
  const _BreachTile({required this.breach});

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppColors.red;
      case 'high':
        return AppColors.orange;
      case 'medium':
        return AppColors.amber;
      case 'low':
        return AppColors.green;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _breachIcon(String type) {
    switch (type.toLowerCase()) {
      case 'drowsiness':
        return Icons.bedtime;
      case 'eye_closure':
        return Icons.visibility_off;
      case 'distraction':
        return Icons.phone_android;
      case 'yawning':
        return Icons.sentiment_dissatisfied;
      case 'camera_obstructed':
        return Icons.videocam_off;
      default:
        return Icons.warning;
    }
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return 'Unknown';
    DateTime dt;
    if (ts is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true);
    } else if (ts is String) {
      dt = DateTime.tryParse(ts) ?? DateTime.now();
    } else if (ts is DateTime) {
      dt = ts;
    } else {
      return 'Unknown';
    }
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MM/dd HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final type = breach['breachType']?.toString() ?? 'unknown';
    final severity = breach['severity']?.toString() ?? 'medium';
    final color = _severityColor(severity);
    final icon = _breachIcon(type);
    final vehicle = breach['vehicleName']?.toString() ?? breach['vehicleId']?.toString() ?? 'Unknown';
    final driver = breach['driverName']?.toString() ?? breach['driverId']?.toString() ?? 'Unknown';
    final time = _formatTime(breach['timestamp'] ?? breach['ts']);
    final confidence = breach['confidence'] != null
        ? '${(breach['confidence'] * 100).round()}%'
        : '';
    final duration = breach['durationMs'] != null
        ? '${(breach['durationMs'] / 1000).toStringAsFixed(1)}s'
        : '';

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(type.replaceAll('_', ' ').toUpperCase()),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow('Vehicle', vehicle),
                  _detailRow('Driver', driver),
                  _detailRow('Severity', severity.toUpperCase()),
                  _detailRow('Time', _formatTime(breach['timestamp'] ?? breach['ts'])),
                  _detailRow('Duration', duration),
                  _detailRow('Confidence', confidence),
                  if (breach['ear'] != null)
                    _detailRow('EAR', breach['ear'].toString()),
                  if (breach['detail'] != null)
                    _detailRow('Detail', breach['detail'].toString()),
                  if (breach['snapshot'] != null)
                    _detailRow('Snapshot', 'Available (base64)'),
                  if (breach['tripId'] != null)
                    _detailRow('Trip ID', breach['tripId'].toString()),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.text, fontSize: 12))),
        ],
      ),
    );
  }
}