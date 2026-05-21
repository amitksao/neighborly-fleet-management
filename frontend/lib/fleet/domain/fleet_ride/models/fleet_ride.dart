enum FleetRideStatus {
  requested,
  accepted,
  inProgress,
  completed,
  cancelled,
}

class FleetTribe {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final int memberCount;
  final bool isPublic;

  const FleetTribe({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.memberCount,
    required this.isPublic,
  });

  factory FleetTribe.fromJson(Map<String, dynamic> json) {
    return FleetTribe(
      id: json['community_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['pfp'] as String?,
      memberCount: (json['riders'] as List?)?.length ?? 0,
      isPublic: json['is_public'] as bool? ?? true,
    );
  }
}

class FleetRide {
  final String id;
  final String riderId;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? driverProfilePicture;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffAddress;
  final double? estimatedDistance;
  final String? estimatedDuration;
  final DateTime scheduledAt;
  final double fare;
  final FleetRideStatus status;
  final String? fleetId;
  final int assignmentAttempts;
  final DateTime? completedAt;

  const FleetRide({
    required this.id,
    required this.riderId,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverProfilePicture,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffAddress,
    this.estimatedDistance,
    this.estimatedDuration,
    required this.scheduledAt,
    required this.fare,
    required this.status,
    this.fleetId,
    required this.assignmentAttempts,
    this.completedAt,
  });

  factory FleetRide.fromJson(Map<String, dynamic> json) {
    final driverJson = json['driver'] as Map<String, dynamic>?;
    return FleetRide(
      id: json['id'] as String,
      riderId: (json['rider'] as Map<String, dynamic>?)?['id'] as String? ?? '',
      driverId: driverJson?['id'] as String?,
      driverName: driverJson?['name'] as String?,
      driverPhone: driverJson?['phone'] as String?,
      driverProfilePicture: driverJson?['profile_picture'] as String?,
      pickupLatitude: (json['pickup_latitude'] as num).toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num).toDouble(),
      pickupAddress: json['pickup_address'] as String,
      dropoffLatitude: (json['dropoff_latitude'] as num).toDouble(),
      dropoffLongitude: (json['dropoff_longitude'] as num).toDouble(),
      dropoffAddress: json['dropoff_address'] as String,
      estimatedDistance: json['estimated_distance'] != null
          ? (json['estimated_distance'] as num).toDouble()
          : null,
      estimatedDuration: json['estimated_duration'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      fare: (json['fare'] as num).toDouble(),
      status: _parseStatus(json['status'] as String),
      fleetId: json['fleet_id'] as String?,
      assignmentAttempts: json['assignment_attempts'] as int? ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  static FleetRideStatus _parseStatus(String raw) {
    switch (raw) {
      case 'ACCEPTED':
        return FleetRideStatus.accepted;
      case 'IN_PROGRESS':
        return FleetRideStatus.inProgress;
      case 'COMPLETED':
        return FleetRideStatus.completed;
      case 'CANCELLED':
        return FleetRideStatus.cancelled;
      default:
        return FleetRideStatus.requested;
    }
  }
}
