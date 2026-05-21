import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../application/blocs/fleet_ride_bloc.dart';

class FleetInviteAcceptScreen extends StatefulWidget {
  final String token;
  const FleetInviteAcceptScreen({super.key, required this.token});

  @override
  State<FleetInviteAcceptScreen> createState() =>
      _FleetInviteAcceptScreenState();
}

class _FleetInviteAcceptScreenState extends State<FleetInviteAcceptScreen> {
  @override
  void initState() {
    super.initState();
    // Validate token as soon as screen opens
    context.read<FleetRideBloc>().add(FleetInviteTokenValidated(widget.token));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Invitation')),
      body: BlocConsumer<FleetRideBloc, FleetRideState>(
        listener: (context, state) {
          if (state is FleetInviteAcceptedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invitation accepted! Background check initiated.'),
              ),
            );
            Navigator.of(context).pushReplacementNamed('/driver/home');
          } else if (state is FleetRideError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is FleetRideLoading || state is FleetRideInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FleetInviteValid) {
            final fleet = state.fleetInfo['fleet'] as Map<String, dynamic>?;
            final companyName = fleet?['company_name'] ?? 'A fleet company';
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 80, color: Colors.blue),
                  const SizedBox(height: 24),
                  Text(
                    'You\'re invited to join',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    companyName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'By accepting, you agree to undergo a background check. You\'ll be notified of the result within 48 hours.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context
                          .read<FleetRideBloc>()
                          .add(FleetInviteAccepted(widget.token)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Accept & Start Background Check'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            );
          }

          if (state is FleetRideError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Invalid or expired invitation link.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
