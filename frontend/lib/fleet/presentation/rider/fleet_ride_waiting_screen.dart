import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/blocs/fleet_ride_bloc.dart';
import '../../domain/fleet_ride/models/fleet_ride.dart';

/// Shown immediately after booking while the system searches for a driver.
/// Polls the ride status every 5 seconds. Navigates to /fleet/ride-active
/// when a driver accepts, or shows a cancellation message if no driver found.
class FleetRideWaitingScreen extends StatefulWidget {
  final FleetRide ride;
  const FleetRideWaitingScreen({super.key, required this.ride});

  @override
  State<FleetRideWaitingScreen> createState() => _FleetRideWaitingScreenState();
}

class _FleetRideWaitingScreenState extends State<FleetRideWaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Start polling
    context.read<FleetRideBloc>().add(FleetRidePollStarted(widget.ride.id));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    context.read<FleetRideBloc>().add(FleetRidePollStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent accidental back-navigation while waiting
      onWillPop: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Cancel ride?'),
            content: const Text(
                'Going back will cancel your ride request. Are you sure?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes, cancel',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        return confirmed ?? false;
      },
      child: Scaffold(
        body: BlocListener<FleetRideBloc, FleetRideState>(
          listener: (context, state) {
            if (state is FleetRideUpdated &&
                (state.ride.status == FleetRideStatus.accepted ||
                    state.ride.status == FleetRideStatus.inProgress)) {
              Navigator.of(context).pushReplacementNamed(
                '/fleet/ride-active',
                arguments: state.ride,
              );
            } else if (state is FleetRideCancelledBySystem) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'No drivers available at this time. Please try again.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated pulse indicator
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 120 + _pulseController.value * 20,
                        height: 120 + _pulseController.value * 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1 + _pulseController.value * 0.1),
                        ),
                        child: const Center(
                          child: Icon(Icons.local_taxi, size: 56),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Finding your driver...',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'re searching the fleet driver pool. This usually takes less than a minute.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 40),
                  // Ride summary card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _addressRow(
                            icon: Icons.trip_origin,
                            color: Colors.green,
                            label: 'Pickup',
                            address: widget.ride.pickupAddress,
                          ),
                          const Divider(height: 24),
                          _addressRow(
                            icon: Icons.location_on,
                            color: Colors.red,
                            label: 'Dropoff',
                            address: widget.ride.dropoffAddress,
                          ),
                          if (widget.ride.estimatedDuration != null) ...[
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Est. ${widget.ride.estimatedDuration}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressRow({
    required IconData icon,
    required Color color,
    required String label,
    required String address,
  }) {
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
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
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
