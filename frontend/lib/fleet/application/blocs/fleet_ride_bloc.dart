import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/fleet_ride/fleet_ride_repository.dart';
import '../../domain/fleet_ride/models/fleet_ride.dart';

// ─────────── Events ───────────
abstract class FleetRideEvent {}

class FleetTribesRequested extends FleetRideEvent {
  final int page;
  FleetTribesRequested({this.page = 1});
}

class FleetTribeJoined extends FleetRideEvent {
  final String tribeId;
  FleetTribeJoined(this.tribeId);
}

class FleetRideBooked extends FleetRideEvent {
  final String fleetTribeId;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffAddress;
  final DateTime scheduledAt;

  FleetRideBooked({
    required this.fleetTribeId,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffAddress,
    required this.scheduledAt,
  });
}

class FleetRideAccepted extends FleetRideEvent {
  final String rideId;
  FleetRideAccepted(this.rideId);
}

class FleetRideDeclined extends FleetRideEvent {
  final String rideId;
  FleetRideDeclined(this.rideId);
}

class FleetRideCompleted extends FleetRideEvent {
  final String rideId;
  FleetRideCompleted(this.rideId);
}

class FleetInviteTokenValidated extends FleetRideEvent {
  final String token;
  FleetInviteTokenValidated(this.token);
}

class FleetInviteAccepted extends FleetRideEvent {
  final String token;
  FleetInviteAccepted(this.token);
}

/// Start polling a ride every [intervalSeconds] until it reaches a terminal state
class FleetRidePollStarted extends FleetRideEvent {
  final String rideId;
  final int intervalSeconds;
  FleetRidePollStarted(this.rideId, {this.intervalSeconds = 5});
}

/// Stop the active polling subscription
class FleetRidePollStopped extends FleetRideEvent {}

/// Estimate fare before booking
class FleetFareEstimateRequested extends FleetRideEvent {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String fleetId;

  FleetFareEstimateRequested({
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.fleetId,
  });
}

// ─────────── States ───────────
abstract class FleetRideState {}

class FleetRideInitial extends FleetRideState {}

class FleetRideLoading extends FleetRideState {}

class FleetTribesLoaded extends FleetRideState {
  final List<FleetTribe> tribes;
  FleetTribesLoaded(this.tribes);
}

class FleetTribeJoinedState extends FleetRideState {
  final FleetTribe tribe;
  FleetTribeJoinedState(this.tribe);
}

class FleetRideBookedState extends FleetRideState {
  final FleetRide ride;
  FleetRideBookedState(this.ride);
}

class FleetRideUpdated extends FleetRideState {
  final FleetRide ride;
  FleetRideUpdated(this.ride);
}

class FleetInviteValid extends FleetRideState {
  final Map<String, dynamic> fleetInfo;
  FleetInviteValid(this.fleetInfo);
}

class FleetInviteAcceptedState extends FleetRideState {}

class FleetRideActionSuccess extends FleetRideState {
  final String message;
  FleetRideActionSuccess(this.message);
}

class FleetRideError extends FleetRideState {
  final String message;
  FleetRideError(this.message);
}

class FleetRidePolling extends FleetRideState {
  final FleetRide ride;
  FleetRidePolling(this.ride);
}

class FleetRideCancelledBySystem extends FleetRideState {
  final String rideId;
  FleetRideCancelledBySystem(this.rideId);
}

class FleetFareEstimateLoaded extends FleetRideState {
  final FareEstimate estimate;
  FleetFareEstimateLoaded(this.estimate);
}

// ─────────── BLoC ───────────
class FleetRideBloc extends Bloc<FleetRideEvent, FleetRideState> {
  final FleetRideRepository repository;
  Timer? _pollTimer;

  FleetRideBloc(this.repository) : super(FleetRideInitial()) {
    on<FleetTribesRequested>(_onTribesRequested);
    on<FleetTribeJoined>(_onTribeJoined);
    on<FleetRideBooked>(_onRideBooked);
    on<FleetRideAccepted>(_onRideAccepted);
    on<FleetRideDeclined>(_onRideDeclined);
    on<FleetRideCompleted>(_onRideCompleted);
    on<FleetInviteTokenValidated>(_onInviteValidated);
    on<FleetInviteAccepted>(_onInviteAccepted);
    on<FleetRidePollStarted>(_onPollStarted);
    on<FleetRidePollStopped>(_onPollStopped);
    on<FleetFareEstimateRequested>(_onFareEstimateRequested);
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }

  Future<void> _onTribesRequested(
    FleetTribesRequested event,
    Emitter<FleetRideState> emit,
  ) async {
    emit(FleetRideLoading());
    try {
      final tribes = await repository.discoverFleetTribes(page: event.page);
      emit(FleetTribesLoaded(tribes));
    } catch (e) {
      emit(FleetRideError(e.toString()));
    }
  }

  Future<void> _onTribeJoined(
    FleetTribeJoined event,
    Emitter<FleetRideState> emit,
  ) async {
    emit(FleetRideLoading());
    try {
      final tribe = await repository.joinFleetTribe(event.tribeId);
      emit(FleetTribeJoinedState(tribe));
    } catch (e) {
      emit(FleetRideError(e.toString()));
    }
  }

  Future<void> _onRideBooked(
    FleetRideBooked event,
    Emitter<FleetRideState> emit,
  ) async {
    emit(FleetRideLoading());
    try {
      final ride = await repository.bookFleetRide(
        fleetTribeId: event.fleetTribeId,
        pickupLatitude: event.pickupLatitude,
        pickupLongitude: event.pickupLongitude,
        pickupAddress: event.pickupAddress,
        dropoffLatitude: event.dropoffLatitude,
        dropoffLongitude: event.dropoffLongitude,
        dropoffAddress: event.dropoffAddress,
        scheduledAt: event.scheduledAt,
      );
      emit(FleetRideBookedState(ride));
    } catch (e) {
      emit(FleetRideError(e.toString()));
    }
  }

  Future<void> _onRideAccepted(
    FleetRideAccepted event,
    Emitter<FleetRideState> emit,
  ) async {
    emit(FleetRideLoading());
    try {
      final ride = await repository.acceptRide(event.rideId);
      emit(FleetRideUpdated(ride));
    } catch (e) {
      emit(FleetRideError(e.toString()));
    }
  }

  Future<void> _onRideDeclined(
    FleetRideDeclined event,
    Emitter<FleetRideState> emit,
  ) async {
    try {
      await repository.declineRide(event.rideId);
      emit(FleetRideActionSuccess('Ride declined'));
    } catch (e) {
      emit(FleetRideError(e.toString()));
    }
  }

  Future<void> _onRideCompleted(
    FleetRideCompleted event,
    Emitter<FleetRideState> emit,
  ) async {
    emit(FleetRideLoading());
    try {
      final ride = await repository.completeRide(event.rideId);
      emit(FleetRideUpdated(ride));
    } catch (e) {
      emit(FleetRideError(e.toString()));
    }
  }

  Future<void> _onInviteValidated(
    FleetInviteTokenValidated event,
    Emitter<FleetRideState> emit,
  ) async {
    emit(FleetRideLoading());
    try {
      final info = await repository.validateInviteToken(event.token);
      emit(FleetInviteValid(info));
    } catch (e) {
      emit(FleetRideError(e.toString()));
    }
  }

  Future<void> _onInviteAccepted(
    FleetInviteAccepted event,
    Emitter<FleetRideState> emit,
  ) async {
    emit(FleetRideLoading());
    try {
      await repository.acceptDriverInvite(event.token);
      emit(FleetInviteAcceptedState());
    } catch (e) {
      emit(FleetRideError(e.toString()));
    }
  }

  Future<void> _onPollStarted(
    FleetRidePollStarted event,
    Emitter<FleetRideState> emit,
  ) async {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(seconds: event.intervalSeconds),
      (_) { if (!isClosed) add(FleetRidePollStarted(event.rideId, intervalSeconds: event.intervalSeconds)); },
    );

    try {
      final ride = await repository.getRide(event.rideId);
      if (ride.status == FleetRideStatus.cancelled) {
        _pollTimer?.cancel();
        emit(FleetRideCancelledBySystem(event.rideId));
      } else if (ride.status == FleetRideStatus.accepted || ride.status == FleetRideStatus.inProgress) {
        _pollTimer?.cancel();
        emit(FleetRideUpdated(ride));
      } else {
        emit(FleetRidePolling(ride));
      }
    } catch (e) {
      // Swallow polling errors — don't crash the waiting screen
    }
  }

  Future<void> _onPollStopped(
    FleetRidePollStopped event,
    Emitter<FleetRideState> emit,
  ) async {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _onFareEstimateRequested(
    FleetFareEstimateRequested event,
    Emitter<FleetRideState> emit,
  ) async {
    try {
      final estimate = await repository.estimateFare(
        pickupLat: event.pickupLat,
        pickupLng: event.pickupLng,
        dropoffLat: event.dropoffLat,
        dropoffLng: event.dropoffLng,
        fleetId: event.fleetId,
      );
      emit(FleetFareEstimateLoaded(estimate));
    } catch (e) {
      // Non-fatal — fare estimate failure should not block booking
    }
  }
}
