import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../application/blocs/fleet_ride_bloc.dart';
import '../../domain/fleet_ride/fleet_ride_repository.dart';
import '../../domain/fleet_ride/models/fleet_ride.dart';
import '../widgets/address_search_field.dart';

class FleetRideBookingScreen extends StatefulWidget {
  final FleetTribe tribe;
  /// fleetId is required for fare estimation — passed alongside tribe
  final String fleetId;

  const FleetRideBookingScreen({
    super.key,
    required this.tribe,
    required this.fleetId,
  });

  @override
  State<FleetRideBookingScreen> createState() => _FleetRideBookingScreenState();
}

class _FleetRideBookingScreenState extends State<FleetRideBookingScreen> {
  DateTime _scheduledAt = DateTime.now().add(const Duration(minutes: 30));

  PlaceDetail? _pickup;
  PlaceDetail? _dropoff;
  FareEstimate? _fareEstimate;
  bool _estimatingFare = false;

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _onLocationSet() async {
    if (_pickup == null || _dropoff == null) return;
    setState(() => _estimatingFare = true);
    try {
      final repo = context.read<FleetRideRepository>();
      final estimate = await repo.estimateFare(
        pickupLat: _pickup!.latitude,
        pickupLng: _pickup!.longitude,
        dropoffLat: _dropoff!.latitude,
        dropoffLng: _dropoff!.longitude,
        fleetId: widget.fleetId,
      );
      if (mounted) setState(() => _fareEstimate = estimate);
    } catch (_) {
      // Non-fatal — proceed without estimate
    } finally {
      if (mounted) setState(() => _estimatingFare = false);
    }
  }

  void _book() {
    if (_pickup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup address')),
      );
      return;
    }
    if (_dropoff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a dropoff address')),
      );
      return;
    }
    context.read<FleetRideBloc>().add(FleetRideBooked(
          fleetTribeId: widget.tribe.id,
          pickupLatitude: _pickup!.latitude,
          pickupLongitude: _pickup!.longitude,
          pickupAddress: _pickup!.address,
          dropoffLatitude: _dropoff!.latitude,
          dropoffLongitude: _dropoff!.longitude,
          dropoffAddress: _dropoff!.address,
          scheduledAt: _scheduledAt,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d • h:mm a');
    final repo = context.read<FleetRideRepository>();

    return Scaffold(
      appBar: AppBar(title: Text('Book with ${widget.tribe.name}')),
      body: BlocConsumer<FleetRideBloc, FleetRideState>(
        listener: (context, state) {
          if (state is FleetRideBookedState) {
            Navigator.of(context).pushReplacementNamed(
              '/fleet/ride-waiting',
              arguments: state.ride,
            );
          } else if (state is FleetRideError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is FleetRideLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tribe info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Booking through ${widget.tribe.name}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Where are you going?',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Pickup address search
                AddressSearchField(
                  repository: repo,
                  label: 'Pickup Address',
                  onPlaceSelected: (place) {
                    setState(() => _pickup = place);
                    _onLocationSet();
                  },
                ),
                const SizedBox(height: 12),

                // Dropoff address search
                AddressSearchField(
                  repository: repo,
                  label: 'Dropoff Address',
                  onPlaceSelected: (place) {
                    setState(() => _dropoff = place);
                    _onLocationSet();
                  },
                ),
                const SizedBox(height: 20),

                // Fare estimate card
                if (_estimatingFare)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Estimating fare...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                else if (_fareEstimate != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_money, color: Colors.green),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fareEstimate!.fareEstimate != null
                                  ? '\$${_fareEstimate!.fareEstimate!.toStringAsFixed(2)} estimated'
                                  : 'Fare unavailable',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (_fareEstimate!.distanceKm != null &&
                                _fareEstimate!.duration != null)
                              Text(
                                '${_fareEstimate!.distanceKm!.toStringAsFixed(1)} km • ${_fareEstimate!.duration}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text('When?',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule),
                        const SizedBox(width: 12),
                        Text(dateFmt.format(_scheduledAt)),
                        const Spacer(),
                        const Icon(Icons.edit_calendar_outlined,
                            color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A driver will be automatically assigned from the fleet pool. '
                          'You\'ll be notified when confirmed.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _book,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Request Ride'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
