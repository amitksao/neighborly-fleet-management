import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../application/blocs/fleet_ride_bloc.dart';
import '../../../domain/fleet_ride/models/fleet_ride.dart';

/// Driver view for an active fleet ride.
/// Driver can mark the ride as in-progress (picked up rider) and then complete it.
class FleetDriverActiveScreen extends StatefulWidget {
  final FleetRide ride;
  const FleetDriverActiveScreen({super.key, required this.ride});

  @override
  State<FleetDriverActiveScreen> createState() => _FleetDriverActiveScreenState();
}

class _FleetDriverActiveScreenState extends State<FleetDriverActiveScreen> {
  late FleetRide _ride;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
  }

  void _completeRide() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete Ride'),
        content: const Text(
            'Confirm that you have dropped off the rider and the ride is complete.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context
                  .read<FleetRideBloc>()
                  .add(FleetRideCompleted(_ride.id));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Ride'),
        automaticallyImplyLeading: false,
      ),
      body: BlocConsumer<FleetRideBloc, FleetRideState>(
        listener: (context, state) {
          if (state is FleetRideUpdated) {
            setState(() => _ride = state.ride);
            if (state.ride.status == FleetRideStatus.completed) {
              Navigator.of(context).popUntil((r) => r.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ride completed. Payout will be processed shortly.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else if (state is FleetRideError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is FleetRideLoading;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator
                  _StatusChip(status: _ride.status),
                  const SizedBox(height: 24),

                  // Rider info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rider',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const CircleAvatar(
                                  child: Icon(Icons.person)),
                              const SizedBox(width: 12),
                              Text(
                                _ride.riderId.isNotEmpty
                                    ? 'Rider #${_ride.riderId.substring(0, 8)}'
                                    : 'Rider',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Route card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _AddressRow(
                            icon: Icons.trip_origin,
                            color: Colors.green,
                            label: 'Pickup',
                            address: _ride.pickupAddress,
                          ),
                          const Divider(height: 24),
                          _AddressRow(
                            icon: Icons.location_on,
                            color: Colors.red,
                            label: 'Dropoff',
                            address: _ride.dropoffAddress,
                          ),
                          if (_ride.estimatedDuration != null) ...[
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Est. ${_ride.estimatedDuration}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                                if (_ride.estimatedDistance != null) ...[
                                  const Text('  •  ',
                                      style: TextStyle(color: Colors.grey)),
                                  Text(
                                    '${_ride.estimatedDistance!.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Complete ride button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _completeRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('Complete Ride',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final FleetRideStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      FleetRideStatus.accepted => ('Head to Pickup', Colors.blue),
      FleetRideStatus.inProgress => ('Ride In Progress', Colors.green),
      _ => ('Active Ride', Colors.orange),
    };
    return Chip(
      label: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _AddressRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(address,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
