import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../application/blocs/fleet_ride_bloc.dart';
import '../../../domain/fleet_ride/models/fleet_ride.dart';

class FleetRideAssignmentScreen extends StatefulWidget {
  final FleetRide ride;
  const FleetRideAssignmentScreen({super.key, required this.ride});

  @override
  State<FleetRideAssignmentScreen> createState() =>
      _FleetRideAssignmentScreenState();
}

class _FleetRideAssignmentScreenState
    extends State<FleetRideAssignmentScreen> {
  int _secondsLeft = 60;
  bool _responded = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    while (_secondsLeft > 0 && !_responded) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _secondsLeft--);
    }
    if (!_responded && mounted) {
      // Timeout — auto-decline
      _decline();
    }
  }

  void _accept() {
    setState(() => _responded = true);
    context.read<FleetRideBloc>().add(FleetRideAccepted(widget.ride.id));
  }

  void _decline() {
    setState(() => _responded = true);
    context.read<FleetRideBloc>().add(FleetRideDeclined(widget.ride.id));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent back during assignment window
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: BlocListener<FleetRideBloc, FleetRideState>(  // ignore: deprecated_member_use
          listener: (context, state) {
            if (state is FleetRideUpdated) {
              Navigator.of(context).pushReplacementNamed(
                '/fleet/ride-active',
                arguments: state.ride,
              );
            } else if (state is FleetRideActionSuccess) {
              Navigator.of(context).pop();
            } else if (state is FleetRideError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message), backgroundColor: Colors.red),
              );
              Navigator.of(context).pop();
            }
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Timer ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: _secondsLeft / 60,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          color: _secondsLeft > 15
                              ? Colors.blue
                              : Colors.red,
                        ),
                      ),
                      Text(
                        '$_secondsLeft',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'New Ride Assignment',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  // Ride details card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _RouteRow(
                            icon: Icons.trip_origin,
                            color: Colors.green,
                            label: 'Pickup',
                            address: widget.ride.pickupAddress,
                          ),
                          const Divider(height: 20),
                          _RouteRow(
                            icon: Icons.location_on,
                            color: Colors.red,
                            label: 'Dropoff',
                            address: widget.ride.dropoffAddress,
                          ),
                          if (widget.ride.estimatedDuration != null) ...[
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 18),
                                const SizedBox(width: 8),
                                Text('Est. ${widget.ride.estimatedDuration}'),
                                const Spacer(),
                                if (widget.ride.estimatedDistance != null)
                                  Text(
                                    '${widget.ride.estimatedDistance!.toStringAsFixed(1)} km',
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _responded ? null : _decline,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _responded ? null : _accept,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Accept',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(address, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
