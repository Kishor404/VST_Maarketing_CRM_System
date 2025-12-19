class UserModel {
  final int id;
  final String name;
  final String phone;
  final String? address;
  final String? city;
  final String? postalCode;
  final String region;
  final String role;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.city,
    this.postalCode,
    required this.region,
    required this.role,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'],
      city: json['city'],
      postalCode: json['postal_code'],
      region: json['region'] ?? '',
      role: json['role'] ?? '',
      fcmToken: json['fcm_token'],
    );
  }
}
