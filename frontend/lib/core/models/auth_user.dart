import 'dart:convert';

class AuthUser {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;

  /// UUID of the fleet this user manages, or null if not yet a fleet manager.
  final String? fleetManagerOf;

  const AuthUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.fleetManagerOf,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        fleetManagerOf: json['fleetManagerOf'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (fleetManagerOf != null) 'fleetManagerOf': fleetManagerOf,
      };

  String toJsonString() => jsonEncode(toJson());

  factory AuthUser.fromJsonString(String raw) =>
      AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  String get displayName {
    if (firstName != null && lastName != null) return '$firstName $lastName';
    if (firstName != null) return firstName!;
    return email;
  }
}
