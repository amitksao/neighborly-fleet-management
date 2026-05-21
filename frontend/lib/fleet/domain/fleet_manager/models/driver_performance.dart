class DriverPerformance {
  final String driverUserId;
  final int totalRides;
  final int completedRides;
  final int cancelledRides;
  final double completionRate;
  final double totalEarnings;
  final int periodDays;

  const DriverPerformance({
    required this.driverUserId,
    required this.totalRides,
    required this.completedRides,
    required this.cancelledRides,
    required this.completionRate,
    required this.totalEarnings,
    required this.periodDays,
  });

  factory DriverPerformance.fromJson(Map<String, dynamic> json) {
    return DriverPerformance(
      driverUserId: json['driverUserId'] as String,
      totalRides: json['totalRides'] as int,
      completedRides: json['completedRides'] as int,
      cancelledRides: json['cancelledRides'] as int,
      completionRate: (json['completionRate'] as num).toDouble(),
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      periodDays: json['periodDays'] as int,
    );
  }
}
