import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../application/blocs/fleet_dashboard_bloc.dart';
import '../../../domain/fleet_manager/models/fleet_driver.dart';

class FleetDriverRosterScreen extends StatefulWidget {
  final String fleetId;
  const FleetDriverRosterScreen({super.key, required this.fleetId});

  @override
  State<FleetDriverRosterScreen> createState() =>
      _FleetDriverRosterScreenState();
}

class _FleetDriverRosterScreenState extends State<FleetDriverRosterScreen> {
  FleetDriverStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context
        .read<FleetDashboardBloc>()
        .add(FleetDashboardLoaded(widget.fleetId));
  }

  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Driver Email',
                hintText: 'driver@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              decoration: const InputDecoration(
                labelText: 'Personal Message (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailCtrl.text.trim().isNotEmpty) {
                context.read<FleetDashboardBloc>().add(
                      FleetDriverInvited(
                        widget.fleetId,
                        emailCtrl.text.trim(),
                        message: msgCtrl.text.trim().isEmpty
                            ? null
                            : msgCtrl.text.trim(),
                      ),
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Drivers'),
        actions: [
          PopupMenuButton<FleetDriverStatus?>(
            tooltip: 'Filter',
            onSelected: (val) => setState(() => _filterStatus = val),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All')),
              const PopupMenuItem(
                  value: FleetDriverStatus.active, child: Text('Active')),
              const PopupMenuItem(
                  value: FleetDriverStatus.inactive, child: Text('Inactive')),
              const PopupMenuItem(
                  value: FleetDriverStatus.invited, child: Text('Invited')),
              const PopupMenuItem(
                  value: FleetDriverStatus.bgcPending, child: Text('BGC Pending')),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Invite Driver'),
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
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is FleetDashboardLoading || state is FleetDashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FleetDashboardReady) {
            final drivers = _filterStatus == null
                ? state.drivers
                : state.drivers
                    .where((d) => d.status == _filterStatus)
                    .toList();

            if (drivers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No drivers found'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _showInviteDialog,
                      child: const Text('Invite Your First Driver'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: drivers.length,
              itemBuilder: (_, i) => _DriverCard(
                driver: drivers[i],
                fleetId: widget.fleetId,
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final FleetDriver driver;
  final String fleetId;
  const _DriverCard({required this.driver, required this.fleetId});

  Color _statusColor() {
    switch (driver.status) {
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pushNamed(
          '/fleet/driver-detail',
          arguments: {'driver': driver, 'fleetId': fleetId},
        ),
        child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundImage: driver.driverProfilePicture != null
              ? NetworkImage(driver.driverProfilePicture!)
              : null,
          child: driver.driverProfilePicture == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(
          driver.driverName ?? driver.inviteEmail,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (driver.driverPhone != null) Text(driver.driverPhone!),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor().withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                driver.statusLabel,
                style: TextStyle(
                    fontSize: 12,
                    color: _statusColor(),
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        trailing: driver.status == FleetDriverStatus.active
            ? IconButton(
                icon: const Icon(Icons.pause_circle_outline),
                tooltip: 'Deactivate',
                onPressed: () => context.read<FleetDashboardBloc>().add(
                      FleetDriverDeactivated(fleetId, driver.driverUserId!),
                    ),
              )
            : driver.status == FleetDriverStatus.inactive
                ? IconButton(
                    icon: const Icon(Icons.play_circle_outline,
                        color: Colors.green),
                    tooltip: 'Activate',
                    onPressed: () => context.read<FleetDashboardBloc>().add(
                          FleetDriverActivated(fleetId, driver.driverUserId!),
                        ),
                  )
                : null,
        ),
      ),
    );
  }
}
