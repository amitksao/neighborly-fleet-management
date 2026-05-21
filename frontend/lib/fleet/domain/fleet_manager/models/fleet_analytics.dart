class FleetAnalytics {
  final int totalRides;
  final int completedRides;
  final int cancelledRides;
  final double totalEarningsGross;
  final double totalPlatformFees;
  final double totalNetPayouts;
  final int activeDrivers;
  final int inactiveDrivers;
  final double averageRidesPerDriver;
  final int periodDays;

  const FleetAnalytics({
    required this.totalRides,
    required this.completedRides,
    required this.cancelledRides,
    required this.totalEarningsGross,
    required this.totalPlatformFees,
    required this.totalNetPayouts,
    required this.activeDrivers,
    required this.inactiveDrivers,
    required this.averageRidesPerDriver,
    required this.periodDays,
  });

  double get completionRate =>
      totalRides > 0 ? completedRides / totalRides * 100 : 0.0;

  factory FleetAnalytics.fromJson(Map<String, dynamic> json) {
    return FleetAnalytics(
      totalRides: json['totalRides'] as int,
      completedRides: json['completedRides'] as int,
      cancelledRides: json['cancelledRides'] as int,
      totalEarningsGross: (json['totalEarningsGross'] as num).toDouble(),
      totalPlatformFees: (json['totalPlatformFees'] as num).toDouble(),
      totalNetPayouts: (json['totalNetPayouts'] as num).toDouble(),
      activeDrivers: json['activeDrivers'] as int,
      inactiveDrivers: json['inactiveDrivers'] as int,
      averageRidesPerDriver: (json['averageRidesPerDriver'] as num).toDouble(),
      periodDays: json['periodDays'] as int,
    );
  }
}

class FleetPayout {
  final String rideId;
  final double fare;
  final double? platformFeeAmount;
  final String? transferId;
  final DateTime? completedAt;
  final String pickupAddress;
  final String dropoffAddress;

  const FleetPayout({
    required this.rideId,
    required this.fare,
    this.platformFeeAmount,
    this.transferId,
    this.completedAt,
    required this.pickupAddress,
    required this.dropoffAddress,
  });

  double get netAmount => fare - (platformFeeAmount ?? 0);

  factory FleetPayout.fromJson(Map<String, dynamic> json) {
    return FleetPayout(
      rideId: json['id'] as String,
      fare: (json['fare'] as num).toDouble(),
      platformFeeAmount: json['platform_fee_amount'] != null
          ? (json['platform_fee_amount'] as num).toDouble()
          : null,
      transferId: json['fleet_payout_transfer_id'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      pickupAddress: json['pickup_address'] as String,
      dropoffAddress: json['dropoff_address'] as String,
    );
  }
}
