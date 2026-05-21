import 'models/fleet.dart';
import 'models/fleet_driver.dart';
import 'models/fleet_analytics.dart';
import 'models/driver_performance.dart';

abstract class FleetManagerRepository {
  Future<Fleet> registerFleet({
    required String companyName,
    required String companyEmail,
    String? companyPhone,
    String? companyAddress,
    String? logoUrl,
    String? description,
  });

  Future<String> initiateStripeOnboarding(String fleetId);

  Future<Fleet> getFleet(String fleetId);

  Future<Fleet> updateFleet(
    String fleetId, {
    String? companyName,
    String? companyPhone,
    String? companyAddress,
    String? logoUrl,
    String? description,
  });

  Future<void> inviteDriver(String fleetId, String email, {String? message});

  Future<List<FleetDriver>> getFleetDrivers(
    String fleetId, {
    String? status,
    int page = 1,
    int limit = 20,
  });

  Future<FleetDriver> activateDriver(String fleetId, String driverUserId);

  Future<FleetDriver> deactivateDriver(String fleetId, String driverUserId);

  Future<FleetAnalytics> getAnalytics(String fleetId, {int days = 30});

  Future<List<FleetPayout>> getPayoutHistory(
    String fleetId, {
    int page = 1,
    int limit = 20,
  });

  Future<DriverPerformance> getDriverPerformance(
    String fleetId,
    String driverUserId, {
    int days = 30,
  });
}
