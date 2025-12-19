class CustomerModel {
  final int id;
  final String name;
  final String phone;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
