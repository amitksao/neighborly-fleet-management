import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/fleet_ride/fleet_ride_repository.dart';

class IFleetRideRepository implements FleetRideRepository {
  final String baseUrl;
  final Future<String?> Function() getToken;

  IFleetRideRepository({required this.baseUrl, required this.getToken});

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<FleetTribe>> discoverFleetTribes({int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fleet/tribes?page=$page&limit=$limit'),
      headers: await _headers(),
    );
    _assertSuccess(response);
    final data = _decode(response)['data']['data'] as List;
    return data.map((e) => FleetTribe.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<FleetTribe> joinFleetTribe(String tribeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fleet/tribes/$tribeId/join'),
      headers: await _headers(),
    );
    _assertSuccess(response);
    return FleetTribe.fromJson(_decode(response)['data']);
  }

  @override
  Future<FleetRide> bookFleetRide({
    required String fleetTribeId,
    required double pickupLatitude,
    required double pickupLongitude,
    required String pickupAddress,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String dropoffAddress,
    required DateTime scheduledAt,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fleet/rides'),
      headers: await _headers(),
      body: jsonEncode({
        'fleet_tribe_id': fleetTribeId,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'pickup_address': pickupAddress,
        'dropoff_latitude': dropoffLatitude,
        'dropoff_longitude': dropoffLongitude,
        'dropoff_address': dropoffAddress,
        'scheduled_at': scheduledAt.toIso8601String(),
      }),
    );
    _assertSuccess(response);
    return FleetRide.fromJson(_decode(response)['data']);
  }

  @override
  Future<FleetRide> acceptRide(String rideId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fleet/rides/$rideId/accept'),
      headers: await _headers(),
    );
    _assertSuccess(response);
    return FleetRide.fromJson(_decode(response)['data']);
  }

  @override
  Future<void> declineRide(String rideId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fleet/rides/$rideId/decline'),
      headers: await _headers(),
    );
    _assertSuccess(response);
  }

  @override
  Future<FleetRide> completeRide(String rideId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fleet/rides/$rideId/complete'),
      headers: await _headers(),
    );
    _assertSuccess(response);
    return FleetRide.fromJson(_decode(response)['data']);
  }

  @override
  Future<Map<String, dynamic>> validateInviteToken(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fleet/invite/$token'),
      headers: {'Content-Type': 'application/json'},
    );
    _assertSuccess(response);
    return _decode(response)['data'] as Map<String, dynamic>;
  }

  @override
  Future<void> acceptDriverInvite(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fleet/invite/$token/accept'),
      headers: await _headers(),
    );
    _assertSuccess(response);
  }

  @override
  Future<FleetRide> getRide(String rideId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fleet/rides/$rideId'),
      headers: await _headers(),
    );
    _assertSuccess(response);
    return FleetRide.fromJson(_decode(response)['data']);
  }

  @override
  Future<FareEstimate> estimateFare({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String fleetId,
  }) async {
    final uri = Uri.parse('$baseUrl/fleet/rides/estimate').replace(queryParameters: {
      'pickup_lat': pickupLat.toString(),
      'pickup_lng': pickupLng.toString(),
      'dropoff_lat': dropoffLat.toString(),
      'dropoff_lng': dropoffLng.toString(),
      'fleet_id': fleetId,
    });
    final response = await http.get(uri, headers: await _headers());
    _assertSuccess(response);
    return FareEstimate.fromJson(_decode(response)['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<PlaceSuggestion>> searchAddress(String input) async {
    final uri = Uri.parse('$baseUrl/fleet/places/autocomplete')
        .replace(queryParameters: {'input': input});
    final response = await http.get(uri, headers: await _headers());
    _assertSuccess(response);
    final data = _decode(response)['data'];
    final predictions = (data is Map ? data['predictions'] : data) as List? ?? [];
    return predictions
        .map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PlaceDetail> getPlaceDetails(String placeId) async {
    final uri = Uri.parse('$baseUrl/fleet/places/details')
        .replace(queryParameters: {'place_id': placeId});
    final response = await http.get(uri, headers: await _headers());
    _assertSuccess(response);
    final data = _decode(response)['data'];
    final result = (data is Map && data['result'] != null) ? data['result'] : data;
    return PlaceDetail.fromJson(result as Map<String, dynamic>);
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
