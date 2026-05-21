import 'package:get_it/get_it.dart';
import 'config/app_config.dart';
import 'cubits/auth_cubit.dart';
import 'services/auth_service.dart';
import '../fleet/domain/fleet_manager/fleet_manager_repository.dart';
import '../fleet/domain/fleet_ride/fleet_ride_repository.dart';
import '../fleet/infrastructure/fleet_manager/i_fleet_manager_repository.dart';
import '../fleet/infrastructure/fleet_ride/i_fleet_ride_repository.dart';

final getIt = GetIt.instance;

void setupInjection() {
  final authService = AuthService();
  getIt.registerSingleton<AuthService>(authService);

  getIt.registerFactory<AuthCubit>(() => AuthCubit(getIt<AuthService>()));

  getIt.registerLazySingleton<FleetManagerRepository>(
    () => IFleetManagerRepository(
      baseUrl: AppConfig.baseUrl,
      getToken: () => getIt<AuthService>().getToken(),
    ),
  );

  getIt.registerLazySingleton<FleetRideRepository>(
    () => IFleetRideRepository(
      baseUrl: AppConfig.baseUrl,
      getToken: () => getIt<AuthService>().getToken(),
    ),
  );
}
