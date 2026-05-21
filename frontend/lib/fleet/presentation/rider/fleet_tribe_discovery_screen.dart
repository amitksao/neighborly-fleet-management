import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/blocs/fleet_ride_bloc.dart';
import '../../domain/fleet_ride/models/fleet_ride.dart';

class FleetTribeDiscoveryScreen extends StatefulWidget {
  const FleetTribeDiscoveryScreen({super.key});

  @override
  State<FleetTribeDiscoveryScreen> createState() =>
      _FleetTribeDiscoveryScreenState();
}

class _FleetTribeDiscoveryScreenState
    extends State<FleetTribeDiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FleetRideBloc>().add(FleetTribesRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Tribes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search fleet tribes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: BlocConsumer<FleetRideBloc, FleetRideState>(
        listener: (context, state) {
          if (state is FleetTribeJoinedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Joined "${state.tribe.name}" successfully!')),
            );
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
          if (state is FleetTribesLoaded) {
            if (state.tribes.isEmpty) {
              return const Center(child: Text('No fleet tribes available'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.tribes.length,
              itemBuilder: (_, i) => _TribeCard(tribe: state.tribes[i]),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _TribeCard extends StatelessWidget {
  final FleetTribe tribe;
  const _TribeCard({required this.tribe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with logo or placeholder
          Container(
            height: 80,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Center(
              child: tribe.logoUrl != null
                  ? Image.network(tribe.logoUrl!, height: 60, fit: BoxFit.contain)
                  : Icon(Icons.local_shipping,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tribe.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                if (tribe.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    tribe.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${tribe.memberCount} members',
                        style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => context
                          .read<FleetRideBloc>()
                          .add(FleetTribeJoined(tribe.id)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Join'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
