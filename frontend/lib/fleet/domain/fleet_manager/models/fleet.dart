enum FleetStatus {
  pendingApproval,
  approved,
  rejected,
  suspended,
}

class Fleet {
  final String id;
  final String companyName;
  final String companyEmail;
  final String? companyPhone;
  final String? companyAddress;
  final String? logoUrl;
  final String? description;
  final FleetStatus status;
  final String? stripeAccountId;
  final double platformFeePct;
  final String managerUserId;
  final String? tribeId;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime createdAt;

  const Fleet({
    required this.id,
    required this.companyName,
    required this.companyEmail,
    this.companyPhone,
    this.companyAddress,
    this.logoUrl,
    this.description,
    required this.status,
    this.stripeAccountId,
    required this.platformFeePct,
    required this.managerUserId,
    this.tribeId,
    this.rejectionReason,
    this.approvedAt,
    required this.createdAt,
  });

  bool get isApproved => status == FleetStatus.approved;
  bool get isPendingApproval => status == FleetStatus.pendingApproval;
  bool get hasStripeAccount => stripeAccountId != null;

  factory Fleet.fromJson(Map<String, dynamic> json) {
    return Fleet(
      id: json['id'] as String,
      companyName: json['company_name'] as String,
      companyEmail: json['company_email'] as String,
      companyPhone: json['company_phone'] as String?,
      companyAddress: json['company_address'] as String?,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String),
      stripeAccountId: json['stripe_account_id'] as String?,
      platformFeePct: (json['platform_fee_pct'] as num).toDouble(),
      managerUserId: json['manager_user_id'] as String,
      tribeId: json['tribe_id'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_name': companyName,
        'company_email': companyEmail,
        'company_phone': companyPhone,
        'company_address': companyAddress,
        'logo_url': logoUrl,
        'description': description,
        'status': status.name,
        'stripe_account_id': stripeAccountId,
        'platform_fee_pct': platformFeePct,
        'manager_user_id': managerUserId,
        'tribe_id': tribeId,
        'rejection_reason': rejectionReason,
        'approved_at': approvedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  Fleet copyWith({
    String? companyName,
    String? companyPhone,
    String? companyAddress,
    String? logoUrl,
    String? description,
    FleetStatus? status,
    String? stripeAccountId,
    String? tribeId,
  }) {
    return Fleet(
      id: id,
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail,
      companyPhone: companyPhone ?? this.companyPhone,
      companyAddress: companyAddress ?? this.companyAddress,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      status: status ?? this.status,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      platformFeePct: platformFeePct,
      managerUserId: managerUserId,
      tribeId: tribeId ?? this.tribeId,
      rejectionReason: rejectionReason,
      approvedAt: approvedAt,
      createdAt: createdAt,
    );
  }

  static FleetStatus _parseStatus(String raw) {
    switch (raw) {
      case 'approved':
        return FleetStatus.approved;
      case 'rejected':
        return FleetStatus.rejected;
      case 'suspended':
        return FleetStatus.suspended;
      default:
        return FleetStatus.pendingApproval;
    }
  }
}
