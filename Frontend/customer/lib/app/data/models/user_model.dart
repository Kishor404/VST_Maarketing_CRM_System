class UserModel {
  final int id;
  final String name;
  final String phone;
  final String role;
  final String? address;
  final String? region;
  final String? city;
  final String? postalCode;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.address,
    this.region,
    this.city,
    this.postalCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'],
      address: json['address'],
      region: json['region'],
      city: json['city'],
      postalCode: json['postal_code'],
    );
  }
}
