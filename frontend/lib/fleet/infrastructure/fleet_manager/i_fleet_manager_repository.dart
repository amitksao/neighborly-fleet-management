import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/fleet_manager/fleet_manager_repository.dart';
import '../../domain/fleet_manager/models/fleet.dart';
import '../../domain/fleet_manager/models/fleet_driver.dart';
import '../../domain/fleet_manager/models/fleet_analytics.dart';
import '../../domain/fleet_manager/models/driver_performance.dart';

class IFleetManagerRepository implements FleetManagerRepository {
  final String baseUrl;
  final Future<String?> Function() getToken;

  IFleetManagerRepository({required this.baseUrl, required this.getToken});

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<Fleet> registerFleet({
    required String companyName,
    required String companyEmail,
    String? companyPhone,
    String? companyAddress,
    String? logoUrl,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fleet/register'),
      headers: await _headers(),
      body: jsonEncode({
        'company_name': companyName,
        'company_email': companyEmail,
        if (companyPhone != null) 'company_phone': companyPhone,
        if (companyAddress != null) 'company_address': companyAddress,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (description != null) 'description': description,
      }),
    );
    _assertSuccess(response);
    return Fleet.fromJson(_decode(response)['data']);
  }

  @override
  Future<String> initiateStripeOnboarding(String fleetId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fleet/$fleetId/stripe-onboarding'),
      headers: await _headers(),
    );
    _assertSuccess(response);
    return _decode(response)['data']['onboardingUrl'] as String;
  }

  @override
  Future<Fleet> getFleet(String fleetId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fleet/$fleetId'),
      headers: await _headers(),
    );
    _assertSuccess(response);
    return Fleet.fromJson(_decode(response)['data']);
  }

  @override
  Future<Fleet> updateFleet(
    String fleetId, {
    String? companyName,
    String? companyPhone,
    String? companyAddress,
    String? logoUrl,
    String? description,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/fleet/$fleetId'),
      headers: await _headers(),
      body: jsonEncode({
        if (companyName != null) 'company_name': companyName,
        if (companyPhone != null) 'company_phone': companyPhone,
        if (companyAddress != null) 'company_address': companyAddress,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (description != null) 'description': description,
      }),
    );
    _assertSuccess(response);
    return Fleet.fromJson(_decode(response)['data']);
  }

  @override
  Future<void> inviteDriver(String fleetId, String email, {String? message}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fleet/$fleetId/drivers/invite'),
      headers: await _headers(),
      body: jsonEncode({
        'email': email,
        if (message != null) 'message': message,
      }),
    );
    _assertSuccess(response);
  }

  @override
  Future<List<FleetDriver>> getFleetDrivers(
    String fleetId, {
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/fleet/$fleetId/drivers').replace(queryParameters: {
      if (status != null) 'status': status,
      'page': '$page',
      'limit': '$limit',
    });
    final response = await http.get(uri, headers: await _headers());
    _assertSuccess(response);
    final data = _decode(response)['data']['data'] as List;
    return data.map((e) => FleetDriver.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<FleetDriver> activateDriver(String fleetId, String driverUserId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/fleet/$fleetId/drivers/$driverUserId/activate'),
      headers: await _headers(),
    );
    _assertSuccess(response);
    return FleetDriver.fromJson(_decode(response)['data']);
  }

  @override
  Future<FleetDriver> deactivateDriver(String fleetId, String driverUserId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/fleet/$fleetId/drivers/$driverUserId/deactivate'),
      headers: await _headers(),
    );
    _assertSuccess(response);
    return FleetDriver.fromJson(_decode(response)['data']);
  }

  @override
  Future<FleetAnalytics> getAnalytics(String fleetId, {int days = 30}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fleet/$fleetId/analytics?days=$days'),
      headers: await _headers(),
    );
    _assertSuccess(response);
    return FleetAnalytics.fromJson(_decode(response)['data']);
  }

  @override
  Future<List<FleetPayout>> getPayoutHistory(
    String fleetId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fleet/$fleetId/payouts?page=$page&limit=$limit'),
      headers: await _headers(),
    );
    _assertSuccess(response);
    final data = _decode(response)['data']['data'] as List;
    return data.map((e) => FleetPayout.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<DriverPerformance> getDriverPerformance(
    String fleetId,
    String driverUserId, {
    int days = 30,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fleet/$fleetId/drivers/$driverUserId/performance?days=$days'),
      headers: await _headers(),
    );
    _assertSuccess(response);
    return DriverPerformance.fromJson(_decode(response)['data'] as Map<String, dynamic>);
  }

  void _assertSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decode(response);
      throw Exception(body['message'] ?? 'Request failed (${response.statusCode})');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
