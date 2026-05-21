import 'models/fleet_ride.dart';

class FareEstimate {
  final double? distanceKm;
  final String? duration;
  final double? fareEstimate;

  const FareEstimate({this.distanceKm, this.duration, this.fareEstimate});

  factory FareEstimate.fromJson(Map<String, dynamic> json) {
    return FareEstimate(
      distanceKm: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
      duration: json['duration'] as String?,
      fareEstimate: json['fare_estimate'] != null ? (json['fare_estimate'] as num).toDouble() : null,
    );
  }
}

class PlaceSuggestion {
  final String placeId;
  final String description;

  const PlaceSuggestion({required this.placeId, required this.description});

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
    );
  }
}

class PlaceDetail {
  final String placeId;
  final String address;
  final double latitude;
  final double longitude;

  const PlaceDetail({
    required this.placeId,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    final loc = (json['geometry']?['location'] ?? json['location']) as Map<String, dynamic>?;
    return PlaceDetail(
      placeId: json['place_id'] as String,
      address: (json['formatted_address'] ?? json['name'] ?? '') as String,
      latitude: (loc?['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (loc?['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

abstract class FleetRideRepository {
  Future<List<FleetTribe>> discoverFleetTribes({int page = 1, int limit = 20});

  Future<FleetTribe> joinFleetTribe(String tribeId);

  Future<FleetRide> bookFleetRide({
    required String fleetTribeId,
    required double pickupLatitude,
    required double pickupLongitude,
    required String pickupAddress,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String dropoffAddress,
    required DateTime scheduledAt,
  });

  Future<FleetRide> acceptRide(String rideId);

  Future<void> declineRide(String rideId);

  Future<FleetRide> completeRide(String rideId);

  /// Poll a single ride by ID for status updates
  Future<FleetRide> getRide(String rideId);

  /// Estimate fare before booking
  Future<FareEstimate> estimateFare({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String fleetId,
  });

  /// Google Places autocomplete (server-proxied)
  Future<List<PlaceSuggestion>> searchAddress(String input);

  /// Resolve a place_id to coordinates and address
  Future<PlaceDetail> getPlaceDetails(String placeId);

  /// Validates an invite token and returns fleet info (public — no auth)
  Future<Map<String, dynamic>> validateInviteToken(String token);

  /// Accepts a fleet driver invite (requires auth)
  Future<void> acceptDriverInvite(String token);
}
