class CardModel {
  final int id;
  final String model;
  final int customerId;
  final String customerName;

  /// normal | om
  final String cardType;

  /// rajapalayam | ambasamuthiram | ...
  final String region;

  final String address;
  final String? city;
  final String? postalCode;

  final DateTime? installationDate;
  final DateTime? warrantyStartDate;
  final DateTime? warrantyEndDate;

  CardModel({
    required this.id,
    required this.model,
    required this.customerId,
    required this.customerName,
    required this.cardType,
    required this.region,
    required this.address,
    this.city,
    this.postalCode,
    this.installationDate,
    this.warrantyStartDate,
    this.warrantyEndDate,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'],
      model: json['model'],
      customerId: json['customer'],
      customerName: json['customer_name'],
      cardType: json['card_type'],
      region: json['region'],
      address: json['address'],
      city: json['city'],
      postalCode: json['postal_code'],
      installationDate: json['date_of_installation'] != null
          ? DateTime.parse(json['date_of_installation'])
          : null,
      warrantyStartDate: json['warranty_start_date'] != null
          ? DateTime.parse(json['warranty_start_date'])
          : null,
      warrantyEndDate: json['warranty_end_date'] != null
          ? DateTime.parse(json['warranty_end_date'])
          : null,
    );
  }

  /// --------------------------
  /// DERIVED / HELPER GETTERS
  /// --------------------------

  bool get isOtherMachine => cardType == 'om';

  bool get isWarrantyActive {
    if (warrantyEndDate == null) return false;
    return DateTime.now().isBefore(warrantyEndDate!);
  }

  String get cardTypeLabel =>
      cardType == 'om' ? 'Other Machine' : 'Normal';

  String get regionLabel => region[0].toUpperCase() + region.substring(1);
}
