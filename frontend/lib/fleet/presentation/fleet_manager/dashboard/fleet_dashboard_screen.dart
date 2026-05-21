import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../application/blocs/fleet_dashboard_bloc.dart';
import '../../../domain/fleet_manager/models/fleet_analytics.dart';
import '../../../domain/fleet_manager/models/fleet_driver.dart';

class FleetDashboardScreen extends StatefulWidget {
  final String fleetId;
  const FleetDashboardScreen({super.key, required this.fleetId});

  @override
  State<FleetDashboardScreen> createState() => _FleetDashboardScreenState();
}

class _FleetDashboardScreenState extends State<FleetDashboardScreen> {
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context
        .read<FleetDashboardBloc>()
        .add(FleetDashboardLoaded(widget.fleetId, days: _selectedDays));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Dashboard'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (val) {
              setState(() => _selectedDays = val);
              _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 30, child: Text('Last 30 days')),
              PopupMenuItem(value: 60, child: Text('Last 60 days')),
              PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text('$_selectedDays days'),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<FleetDashboardBloc, FleetDashboardState>(
        listener: (context, state) {
          if (state is FleetDashboardActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            _load();
          } else if (state is FleetDashboardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is FleetDashboardLoading || state is FleetDashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FleetDashboardReady) {
            return _buildDashboard(state);
          }
          return const Center(child: Text('Unable to load dashboard'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .pushNamed('/fleet/drivers', arguments: widget.fleetId),
        icon: const Icon(Icons.group_add),
        label: const Text('Manage Drivers'),
      ),
    );
  }

  Widget _buildDashboard(FleetDashboardReady state) {
    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Earnings — Last $_selectedDays Days'),
          const SizedBox(height: 8),
          _EarningsSummary(analytics: state.analytics),
          const SizedBox(height: 20),
          _SectionHeader('Rides'),
          const SizedBox(height: 8),
          _RideStats(analytics: state.analytics),
          const SizedBox(height: 20),
          _SectionHeader('Drivers'),
          const SizedBox(height: 8),
          _DriverSummary(analytics: state.analytics),
          const SizedBox(height: 20),
          _SectionHeader('Recent Payouts'),
          const SizedBox(height: 8),
          if (state.recentPayouts.isEmpty)
            const _EmptyCard(message: 'No payouts yet')
          else
            ...state.recentPayouts.map((p) => _PayoutTile(payout: p)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _EarningsSummary extends StatelessWidget {
  final FleetAnalytics analytics;
  const _EarningsSummary({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$');
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Gross',
            value: fmt.format(analytics.totalEarningsGross),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Platform Fee',
            value: fmt.format(analytics.totalPlatformFees),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Net Payout',
            value: fmt.format(analytics.totalNetPayouts),
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}

class _RideStats extends StatelessWidget {
  final FleetAnalytics analytics;
  const _RideStats({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Rides',
            value: '${analytics.totalRides}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Completed',
            value: '${analytics.completedRides}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Completion %',
            value: '${analytics.completionRate.toStringAsFixed(1)}%',
            color: analytics.completionRate > 80 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _DriverSummary extends StatelessWidget {
  final FleetAnalytics analytics;
  const _DriverSummary({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Active',
            value: '${analytics.activeDrivers}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Inactive',
            value: '${analytics.inactiveDrivers}',
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Avg Rides/Driver',
            value: analytics.averageRidesPerDriver.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatCard({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
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
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  final FleetPayout payout;
  const _PayoutTile({required this.payout});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$');
    final dateFmt = DateFormat('MMM d, yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.payments_outlined, color: Colors.green),
        title: Text(
          '${payout.pickupAddress} → ${payout.dropoffAddress}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: payout.completedAt != null
            ? Text(dateFmt.format(payout.completedAt!))
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              fmt.format(payout.netAmount),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green),
            ),
            Text(
              'Fare: ${fmt.format(payout.fare)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(message,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
