enum FleetDriverStatus {
  invited,
  bgcPending,
  active,
  inactive,
  rejected,
}

class FleetDriver {
  final String id;
  final String fleetId;
  final String? driverUserId;
  final FleetDriverStatus status;
  final String inviteEmail;
  final DateTime? inviteExpiresAt;
  final DateTime? activatedAt;
  final DateTime? deactivatedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  // Optional joined driver user fields
  final String? driverName;
  final String? driverPhone;
  final String? driverProfilePicture;
  final double? driverRating;

  const FleetDriver({
    required this.id,
    required this.fleetId,
    this.driverUserId,
    required this.status,
    required this.inviteEmail,
    this.inviteExpiresAt,
    this.activatedAt,
    this.deactivatedAt,
    this.rejectionReason,
    required this.createdAt,
    this.driverName,
    this.driverPhone,
    this.driverProfilePicture,
    this.driverRating,
  });

  bool get isActive => status == FleetDriverStatus.active;

  factory FleetDriver.fromJson(Map<String, dynamic> json) {
    final driverJson = json['driver'] as Map<String, dynamic>?;
    return FleetDriver(
      id: json['id'] as String,
      fleetId: json['fleet_id'] as String,
      driverUserId: json['driver_user_id'] as String?,
      status: _parseStatus(json['status'] as String),
      inviteEmail: json['invite_email'] as String,
      inviteExpiresAt: json['invite_expires_at'] != null
          ? DateTime.parse(json['invite_expires_at'] as String)
          : null,
      activatedAt: json['activated_at'] != null
          ? DateTime.parse(json['activated_at'] as String)
          : null,
      deactivatedAt: json['deactivated_at'] != null
          ? DateTime.parse(json['deactivated_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      driverName: driverJson?['name'] as String?,
      driverPhone: driverJson?['phone'] as String?,
      driverProfilePicture: driverJson?['profile_picture'] as String?,
      driverRating: driverJson?['averageRating'] != null
          ? (driverJson!['averageRating'] as num).toDouble()
          : null,
    );
  }

  static FleetDriverStatus _parseStatus(String raw) {
    switch (raw) {
      case 'active':
        return FleetDriverStatus.active;
      case 'inactive':
        return FleetDriverStatus.inactive;
      case 'bgc_pending':
        return FleetDriverStatus.bgcPending;
      case 'rejected':
        return FleetDriverStatus.rejected;
      default:
        return FleetDriverStatus.invited;
    }
  }

  String get statusLabel {
    switch (status) {
      case FleetDriverStatus.invited:
        return 'Invite Sent';
      case FleetDriverStatus.bgcPending:
        return 'Background Check Pending';
      case FleetDriverStatus.active:
        return 'Active';
      case FleetDriverStatus.inactive:
        return 'Inactive';
      case FleetDriverStatus.rejected:
        return 'Rejected';
    }
  }
}
