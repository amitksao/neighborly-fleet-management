import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/fleet_manager/fleet_manager_repository.dart';
import '../../domain/fleet_manager/models/fleet_analytics.dart';
import '../../domain/fleet_manager/models/fleet_driver.dart';

// ─────────── Events ───────────
abstract class FleetDashboardEvent {}

class FleetDashboardLoaded extends FleetDashboardEvent {
  final String fleetId;
  final int days;
  FleetDashboardLoaded(this.fleetId, {this.days = 30});
}

class FleetDriverInvited extends FleetDashboardEvent {
  final String fleetId;
  final String email;
  final String? message;
  FleetDriverInvited(this.fleetId, this.email, {this.message});
}

class FleetDriverActivated extends FleetDashboardEvent {
  final String fleetId;
  final String driverUserId;
  FleetDriverActivated(this.fleetId, this.driverUserId);
}

class FleetDriverDeactivated extends FleetDashboardEvent {
  final String fleetId;
  final String driverUserId;
  FleetDriverDeactivated(this.fleetId, this.driverUserId);
}

// ─────────── States ───────────
abstract class FleetDashboardState {}

class FleetDashboardInitial extends FleetDashboardState {}

class FleetDashboardLoading extends FleetDashboardState {}

class FleetDashboardReady extends FleetDashboardState {
  final FleetAnalytics analytics;
  final List<FleetDriver> drivers;
  final List<FleetPayout> recentPayouts;
  FleetDashboardReady({
    required this.analytics,
    required this.drivers,
    required this.recentPayouts,
  });
}

class FleetDashboardActionSuccess extends FleetDashboardState {
  final String message;
  FleetDashboardActionSuccess(this.message);
}

class FleetDashboardError extends FleetDashboardState {
  final String message;
  FleetDashboardError(this.message);
}

// ─────────── BLoC ───────────
class FleetDashboardBloc extends Bloc<FleetDashboardEvent, FleetDashboardState> {
  final FleetManagerRepository repository;

  FleetDashboardBloc(this.repository) : super(FleetDashboardInitial()) {
    on<FleetDashboardLoaded>(_onLoad);
    on<FleetDriverInvited>(_onInvite);
    on<FleetDriverActivated>(_onActivate);
    on<FleetDriverDeactivated>(_onDeactivate);
  }

  Future<void> _onLoad(
    FleetDashboardLoaded event,
    Emitter<FleetDashboardState> emit,
  ) async {
    emit(FleetDashboardLoading());
    try {
      final results = await Future.wait([
        repository.getAnalytics(event.fleetId, days: event.days),
        repository.getFleetDrivers(event.fleetId, limit: 50),
        repository.getPayoutHistory(event.fleetId, limit: 10),
      ]);

      emit(FleetDashboardReady(
        analytics: results[0] as FleetAnalytics,
        drivers: results[1] as List<FleetDriver>,
        recentPayouts: results[2] as List<FleetPayout>,
      ));
    } catch (e) {
      emit(FleetDashboardError(e.toString()));
    }
  }

  Future<void> _onInvite(
    FleetDriverInvited event,
    Emitter<FleetDashboardState> emit,
  ) async {
    try {
      await repository.inviteDriver(event.fleetId, event.email,
          message: event.message);
      emit(FleetDashboardActionSuccess('Invite sent to ${event.email}'));
    } catch (e) {
      emit(FleetDashboardError(e.toString()));
    }
  }

  Future<void> _onActivate(
    FleetDriverActivated event,
    Emitter<FleetDashboardState> emit,
  ) async {
    try {
      await repository.activateDriver(event.fleetId, event.driverUserId);
      emit(FleetDashboardActionSuccess('Driver activated'));
    } catch (e) {
      emit(FleetDashboardError(e.toString()));
    }
  }

  Future<void> _onDeactivate(
    FleetDriverDeactivated event,
    Emitter<FleetDashboardState> emit,
  ) async {
    try {
      await repository.deactivateDriver(event.fleetId, event.driverUserId);
      emit(FleetDashboardActionSuccess('Driver deactivated'));
    } catch (e) {
      emit(FleetDashboardError(e.toString()));
    }
  }
}
