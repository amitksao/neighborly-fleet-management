# Fleet Frontend — Integration Guide

## 1. Add http dependency to pubspec.yaml

```yaml
dependencies:
  http: ^1.2.0
  intl: ^0.20.2   # already present in neighborly_app
```

## 2. Register repositories in get_it injection

In `lib/shared/domain/core/configs/injection.dart` (or equivalent):

```dart
import 'package:rider/fleet/infrastructure/fleet_manager/i_fleet_manager_repository.dart';
import 'package:rider/fleet/infrastructure/fleet_ride/i_fleet_ride_repository.dart';
import 'package:rider/fleet/domain/fleet_manager/fleet_manager_repository.dart';
import 'package:rider/fleet/domain/fleet_ride/fleet_ride_repository.dart';

// Inside configureDependencies() or @InjectableInit:
getIt.registerLazySingleton<FleetManagerRepository>(
  () => IFleetManagerRepository(
    baseUrl: AppConfig.serverUrl,
    getToken: () => /* read token from Hive/storage */,
  ),
);

getIt.registerLazySingleton<FleetRideRepository>(
  () => IFleetRideRepository(
    baseUrl: AppConfig.serverUrl,
    getToken: () => /* read token from Hive/storage */,
  ),
);
```

## 3. Register BLoCs in the widget tree

Wrap relevant screens with BlocProviders:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => FleetRegistrationBloc(getIt<FleetManagerRepository>())),
    BlocProvider(create: (_) => FleetDashboardBloc(getIt<FleetManagerRepository>())),
    BlocProvider(create: (_) => FleetRideBloc(getIt<FleetRideRepository>())),
  ],
  child: child,
)
```

## 4. Add fleet routes to routing_config.dart

```dart
// In authorizedNavigation or commonNavigation:
case '/fleet/register':
  return MaterialPageRoute(builder: (_) => BlocProvider(..., child: const FleetRegistrationScreen()));

case '/fleet/pending-approval':
  final fleet = settings.arguments as Fleet;
  return MaterialPageRoute(builder: (_) => FleetPendingApprovalScreen(fleet: fleet));

case '/fleet/dashboard':
  final fleetId = settings.arguments as String;
  return MaterialPageRoute(builder: (_) => FleetDashboardScreen(fleetId: fleetId));

case '/fleet/drivers':
  final fleetId = settings.arguments as String;
  return MaterialPageRoute(builder: (_) => FleetDriverRosterScreen(fleetId: fleetId));

case '/fleet/tribes':
  return MaterialPageRoute(builder: (_) => const FleetTribeDiscoveryScreen());

case '/fleet/ride-booking':
  final tribe = settings.arguments as FleetTribe;
  return MaterialPageRoute(builder: (_) => FleetRideBookingScreen(tribe: tribe));

case '/fleet/ride-assignment':
  final ride = settings.arguments as FleetRide;
  return MaterialPageRoute(builder: (_) => FleetRideAssignmentScreen(ride: ride));

case '/fleet/invite':
  // Deep link: parse token from URI
  final token = settings.arguments as String;
  return MaterialPageRoute(builder: (_) => FleetInviteAcceptScreen(token: token));
```

## 5. Handle deep links for driver invites

In `AppLinkUtil.initDeepLinks`, parse `/fleet/invite/:token` paths and
navigate to `/fleet/invite` route with the token as argument.

## 6. Copy fleet lib directory

Copy `neighborly-fleet-management/frontend/lib/fleet/` into
`neighborly_app/lib/fleet/`.

Update package import prefix from bare paths to `package:rider/fleet/...`.
