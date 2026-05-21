import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../application/blocs/fleet_dashboard_bloc.dart';
import '../../../domain/fleet_manager/models/fleet_driver.dart';
import '../../../domain/fleet_manager/models/driver_performance.dart';
import '../../../domain/fleet_manager/fleet_manager_repository.dart';

class DriverDetailScreen extends StatefulWidget {
  final FleetDriver driver;
  final String fleetId;

  const DriverDetailScreen({
    super.key,
    required this.driver,
    required this.fleetId,
  });

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  DriverPerformance? _performance;
  bool _loadingPerformance = false;
  String? _performanceError;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    if (widget.driver.driverUserId != null) {
      _loadPerformance();
    }
  }

  Future<void> _loadPerformance() async {
    setState(() {
      _loadingPerformance = true;
      _performanceError = null;
    });
    try {
      final repo = context.read<FleetManagerRepository>();
      final perf = await repo.getDriverPerformance(
        widget.fleetId,
        widget.driver.driverUserId!,
        days: _selectedDays,
      );
      if (mounted) setState(() => _performance = perf);
    } catch (e) {
      if (mounted) setState(() => _performanceError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingPerformance = false);
    }
  }

  Color _statusColor(FleetDriverStatus status) {
    switch (status) {
      case FleetDriverStatus.active:
        return Colors.green;
      case FleetDriverStatus.inactive:
        return Colors.grey;
      case FleetDriverStatus.bgcPending:
        return Colors.orange;
      case FleetDriverStatus.rejected:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    final statusColor = _statusColor(driver.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(driver.driverName ?? 'Driver Detail'),
        centerTitle: true,
        actions: [
          if (driver.status == FleetDriverStatus.active)
            IconButton(
              icon: const Icon(Icons.pause_circle_outline),
              tooltip: 'Deactivate',
              onPressed: () {
                context.read<FleetDashboardBloc>().add(
                      FleetDriverDeactivated(widget.fleetId, driver.driverUserId!),
                    );
                Navigator.of(context).pop();
              },
            )
          else if (driver.status == FleetDriverStatus.inactive)
            IconButton(
              icon: const Icon(Icons.play_circle_outline, color: Colors.green),
              tooltip: 'Activate',
              onPressed: () {
                context.read<FleetDashboardBloc>().add(
                      FleetDriverActivated(widget.fleetId, driver.driverUserId!),
                    );
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile Card ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: driver.driverProfilePicture != null
                        ? NetworkImage(driver.driverProfilePicture!)
                        : null,
                    child: driver.driverProfilePicture == null
                        ? const Icon(Icons.person, size: 36)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.driverName ?? driver.inviteEmail,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (driver.driverPhone != null) ...[
                          const SizedBox(height: 4),
                          Text(driver.driverPhone!,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            driver.statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (driver.driverRating != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                driver.driverRating!.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Info Rows ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Invite Email',
                    value: driver.inviteEmail,
                  ),
                  if (driver.activatedAt != null)
                    _InfoRow(
                      icon: Icons.check_circle_outline,
                      label: 'Active Since',
                      value: DateFormat('MMM d, yyyy').format(driver.activatedAt!),
                    ),
                  if (driver.deactivatedAt != null)
                    _InfoRow(
                      icon: Icons.cancel_outlined,
                      label: 'Deactivated',
                      value: DateFormat('MMM d, yyyy').format(driver.deactivatedAt!),
                    ),
                  if (driver.rejectionReason != null)
                    _InfoRow(
                      icon: Icons.info_outline,
                      label: 'Rejection Reason',
                      value: driver.rejectionReason!,
                    ),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Joined',
                    value: DateFormat('MMM d, yyyy').format(driver.createdAt),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Performance Section ──
          if (driver.driverUserId != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  value: _selectedDays,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                    DropdownMenuItem(value: 60, child: Text('60 days')),
                    DropdownMenuItem(value: 90, child: Text('90 days')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedDays = val);
                      _loadPerformance();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingPerformance)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator()))
            else if (_performanceError != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_performanceError!,
                      style: const TextStyle(color: Colors.red)),
                ),
              )
            else if (_performance != null)
              _PerformanceCard(performance: _performance!)
            else
              const SizedBox(),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: Colors.grey),
      title: Text(label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey)),
      subtitle: Text(value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final DriverPerformance performance;
  const _PerformanceCard({required this.performance});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _PerfStat(
                  label: 'Total Rides',
                  value: '${performance.totalRides}',
                ),
                _PerfStat(
                  label: 'Completed',
                  value: '${performance.completedRides}',
                  color: Colors.green,
                ),
                _PerfStat(
                  label: 'Cancelled',
                  value: '${performance.cancelledRides}',
                  color: Colors.red,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _PerfStat(
                  label: 'Completion %',
                  value:
                      '${performance.completionRate.toStringAsFixed(1)}%',
                  color: performance.completionRate >= 80
                      ? Colors.green
                      : Colors.orange,
                ),
                _PerfStat(
                  label: 'Earnings',
                  value: fmt.format(performance.totalEarnings),
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PerfStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _PerfStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
