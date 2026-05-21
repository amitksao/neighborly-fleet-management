import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/blocs/fleet_ride_bloc.dart';
import '../../domain/fleet_ride/models/fleet_ride.dart';

/// Rider view once a driver has been assigned and accepted the ride.
/// Polls every 10s to detect when the ride completes.
class FleetRideActiveScreen extends StatefulWidget {
  final FleetRide ride;
  const FleetRideActiveScreen({super.key, required this.ride});

  @override
  State<FleetRideActiveScreen> createState() => _FleetRideActiveScreenState();
}

class _FleetRideActiveScreenState extends State<FleetRideActiveScreen> {
  late FleetRide _ride;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    // Poll every 10s to detect completion
    context.read<FleetRideBloc>().add(
        FleetRidePollStarted(_ride.id, intervalSeconds: 10));
  }

  @override
  void dispose() {
    context.read<FleetRideBloc>().add(FleetRidePollStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Ride'),
        automaticallyImplyLeading: false,
      ),
      body: BlocListener<FleetRideBloc, FleetRideState>(
        listener: (context, state) {
          if (state is FleetRideUpdated) {
            setState(() => _ride = state.ride);
            if (state.ride.status == FleetRideStatus.completed) {
              _showCompletionDialog(context, state.ride);
            }
          } else if (state is FleetRidePolling) {
            setState(() => _ride = state.ride);
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Status chip
                _StatusBanner(status: _ride.status),
                const SizedBox(height: 24),

                // Driver card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Driver',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: _ride.driverProfilePicture != null
                                  ? NetworkImage(_ride.driverProfilePicture!)
                                  : null,
                              child: _ride.driverProfilePicture == null
                                  ? const Icon(Icons.person, size: 28)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _ride.driverName ?? 'Assigned Driver',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  if (_ride.driverPhone != null)
                                    Text(_ride.driverPhone!,
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Route card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _RouteRow(
                          icon: Icons.trip_origin,
                          color: Colors.green,
                          label: 'Pickup',
                          address: _ride.pickupAddress,
                        ),
                        const Divider(height: 20),
                        _RouteRow(
                          icon: Icons.location_on,
                          color: Colors.red,
                          label: 'Dropoff',
                          address: _ride.dropoffAddress,
                        ),
                        if (_ride.estimatedDuration != null) ...[
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Est. ${_ride.estimatedDuration}',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              if (_ride.estimatedDistance != null) ...[
                                const Text('  •  ', style: TextStyle(color: Colors.grey)),
                                Text(
                                  '${_ride.estimatedDistance!.toStringAsFixed(1)} km',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ],
                        if (_ride.fare > 0) ...[
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Fare', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '\$${_ride.fare.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),

                // Live polling indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5)),
                    SizedBox(width: 8),
                    Text('Tracking ride status...',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, FleetRide ride) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Ride Complete'),
        content: Text(
          ride.fare > 0
              ? 'Your ride is complete. Fare: \$${ride.fare.toStringAsFixed(2)}'
              : 'Your ride is complete. Thank you for riding!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final FleetRideStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      FleetRideStatus.accepted => ('Driver On The Way', Colors.blue, Icons.directions_car),
      FleetRideStatus.inProgress => ('Ride In Progress', Colors.green, Icons.drive_eta),
      FleetRideStatus.completed => ('Ride Complete', Colors.teal, Icons.check_circle),
      FleetRideStatus.cancelled => ('Ride Cancelled', Colors.red, Icons.cancel),
      _ => ('Finding Driver', Colors.orange, Icons.search),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _RouteRow({
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
