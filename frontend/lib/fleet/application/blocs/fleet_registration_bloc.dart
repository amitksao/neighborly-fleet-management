import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/fleet_manager/fleet_manager_repository.dart';
import '../../domain/fleet_manager/models/fleet.dart';

// ─────────── Events ───────────
abstract class FleetRegistrationEvent {}

class FleetRegistrationSubmitted extends FleetRegistrationEvent {
  final String companyName;
  final String companyEmail;
  final String? companyPhone;
  final String? companyAddress;
  final String? logoUrl;
  final String? description;

  FleetRegistrationSubmitted({
    required this.companyName,
    required this.companyEmail,
    this.companyPhone,
    this.companyAddress,
    this.logoUrl,
    this.description,
  });
}

class FleetStripeOnboardingRequested extends FleetRegistrationEvent {
  final String fleetId;
  FleetStripeOnboardingRequested(this.fleetId);
}

class FleetLoaded extends FleetRegistrationEvent {
  final String fleetId;
  FleetLoaded(this.fleetId);
}

// ─────────── States ───────────
abstract class FleetRegistrationState {}

class FleetRegistrationInitial extends FleetRegistrationState {}

class FleetRegistrationLoading extends FleetRegistrationState {}

class FleetRegistrationSuccess extends FleetRegistrationState {
  final Fleet fleet;
  FleetRegistrationSuccess(this.fleet);
}

class FleetRegistrationStripeUrl extends FleetRegistrationState {
  final String onboardingUrl;
  FleetRegistrationStripeUrl(this.onboardingUrl);
}

class FleetRegistrationError extends FleetRegistrationState {
  final String message;
  FleetRegistrationError(this.message);
}

// ─────────── BLoC ───────────
class FleetRegistrationBloc
    extends Bloc<FleetRegistrationEvent, FleetRegistrationState> {
  final FleetManagerRepository repository;

  FleetRegistrationBloc(this.repository) : super(FleetRegistrationInitial()) {
    on<FleetRegistrationSubmitted>(_onSubmit);
    on<FleetStripeOnboardingRequested>(_onStripeOnboarding);
    on<FleetLoaded>(_onLoad);
  }

  Future<void> _onSubmit(
    FleetRegistrationSubmitted event,
    Emitter<FleetRegistrationState> emit,
  ) async {
    emit(FleetRegistrationLoading());
    try {
      final fleet = await repository.registerFleet(
        companyName: event.companyName,
        companyEmail: event.companyEmail,
        companyPhone: event.companyPhone,
        companyAddress: event.companyAddress,
        logoUrl: event.logoUrl,
        description: event.description,
      );
      emit(FleetRegistrationSuccess(fleet));
    } catch (e) {
      emit(FleetRegistrationError(e.toString()));
    }
  }

  Future<void> _onStripeOnboarding(
    FleetStripeOnboardingRequested event,
    Emitter<FleetRegistrationState> emit,
  ) async {
    emit(FleetRegistrationLoading());
    try {
      final url = await repository.initiateStripeOnboarding(event.fleetId);
      emit(FleetRegistrationStripeUrl(url));
    } catch (e) {
      emit(FleetRegistrationError(e.toString()));
    }
  }

  Future<void> _onLoad(
    FleetLoaded event,
    Emitter<FleetRegistrationState> emit,
  ) async {
    emit(FleetRegistrationLoading());
    try {
      final fleet = await repository.getFleet(event.fleetId);
      emit(FleetRegistrationSuccess(fleet));
    } catch (e) {
      emit(FleetRegistrationError(e.toString()));
    }
  }
}
