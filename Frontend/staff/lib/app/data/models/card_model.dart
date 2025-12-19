class CardModel {
  final int id;
  final String address;
  final String city;
  final String model;
  final String cardType;

  CardModel({
    required this.id,
    required this.address,
    required this.city,
    required this.model,
    required this.cardType,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      model: json['model'] ?? '',
      cardType: json['card_type'] ?? '',
    );
  }

  String get fullAddress =>
      [address, city].where((e) => e.isNotEmpty).join(', ');
}
