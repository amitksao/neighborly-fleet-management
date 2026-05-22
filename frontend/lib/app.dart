import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/cubits/auth_cubit.dart';
import 'core/injection.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/stripe_onboarding_screen.dart';
import 'fleet/application/blocs/fleet_dashboard_bloc.dart';
import 'fleet/application/blocs/fleet_registration_bloc.dart';
import 'fleet/application/blocs/fleet_ride_bloc.dart';
import 'fleet/domain/fleet_manager/fleet_manager_repository.dart';
import 'fleet/domain/fleet_manager/models/fleet.dart';
import 'fleet/domain/fleet_ride/fleet_ride_repository.dart';
import 'fleet/domain/fleet_ride/models/fleet_ride.dart';
import 'fleet/presentation/fleet_manager/dashboard/fleet_dashboard_screen.dart';
import 'fleet/presentation/fleet_manager/drivers/fleet_driver_roster_screen.dart';
import 'fleet/domain/fleet_manager/models/fleet_driver.dart';
import 'fleet/presentation/fleet_manager/drivers/driver_detail_screen.dart';
import 'fleet/presentation/fleet_manager/registration/fleet_pending_approval_screen.dart';
import 'fleet/presentation/fleet_manager/registration/fleet_registration_screen.dart';
import 'fleet/presentation/rider/fleet_ride_booking_screen.dart';
import 'fleet/presentation/rider/fleet_ride_waiting_screen.dart';
import 'fleet/presentation/rider/fleet_ride_active_screen.dart';
import 'fleet/presentation/fleet_driver/rides/fleet_driver_active_screen.dart';

class FleetApp extends StatelessWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  const FleetApp({super.key, this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FleetManagerRepository>(
          create: (_) => getIt<FleetManagerRepository>(),
        ),
        RepositoryProvider<FleetRideRepository>(
          create: (_) => getIt<FleetRideRepository>(),
        ),
      ],
      child: _AppWithBlocs(navigatorKey: navigatorKey),
    );
  }
}

class _AppWithBlocs extends StatelessWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  const _AppWithBlocs({this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth — one instance for the entire app lifetime
        BlocProvider<AuthCubit>(
          create: (_) => getIt<AuthCubit>(),
        ),
        // Fleet manager BLoCs — shared so dashboard and driver roster
        // read from the same loaded state
        BlocProvider<FleetRegistrationBloc>(
          create: (_) =>
              FleetRegistrationBloc(getIt<FleetManagerRepository>()),
        ),
        BlocProvider<FleetDashboardBloc>(
          create: (_) => FleetDashboardBloc(getIt<FleetManagerRepository>()),
        ),
        BlocProvider<FleetRideBloc>(
          create: (_) => FleetRideBloc(getIt<FleetRideRepository>()),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Neighborly Fleet',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case '/fleet/register':
        return MaterialPageRoute(
          builder: (_) => const FleetRegistrationScreen(),
        );

      case '/fleet/pending-approval':
        final fleet = settings.arguments as Fleet;
        return MaterialPageRoute(
          builder: (_) => FleetPendingApprovalScreen(fleet: fleet),
        );

      case '/fleet/dashboard':
        final fleetId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => FleetDashboardScreen(fleetId: fleetId),
        );

      case '/fleet/drivers':
        final fleetId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => FleetDriverRosterScreen(fleetId: fleetId),
        );

      case '/fleet/stripe-onboarding':
        final url = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => StripeOnboardingScreen(onboardingUrl: url),
        );

      case '/fleet/driver-detail':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => DriverDetailScreen(
            driver: args['driver'] as FleetDriver,
            fleetId: args['fleetId'] as String,
          ),
        );

      case '/fleet/book-ride':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => FleetRideBookingScreen(
            tribe: args['tribe'] as FleetTribe,
            fleetId: args['fleetId'] as String,
          ),
        );

      case '/fleet/ride-waiting':
        final ride = settings.arguments as FleetRide;
        return MaterialPageRoute(
          builder: (_) => FleetRideWaitingScreen(ride: ride),
        );

      case '/fleet/ride-active':
        final ride = settings.arguments as FleetRide;
        return MaterialPageRoute(
          builder: (_) => FleetRideActiveScreen(ride: ride),
        );

      case '/fleet/driver-active':
        final ride = settings.arguments as FleetRide;
        return MaterialPageRoute(
          builder: (_) => FleetDriverActiveScreen(ride: ride),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route for ${settings.name}')),
          ),
        );
    }
  }
}
