import 'card_model.dart';
import 'customer_model.dart';
import 'service_entry_model.dart';

class ServiceModel {
  final int id;
  final int card;
  final CardModel? cardData;
  final CustomerModel? customerData;
  final String description;
  final String status;
  final String serviceType;
  final String visitType;
  final String preferredDate;
  final String? scheduledAt;
  final List<ServiceEntryModel> entries;

  ServiceModel({
    required this.id,
    required this.card,
    this.cardData,
    this.customerData,
    required this.description,
    required this.status,
    required this.serviceType,
    required this.visitType,
    required this.preferredDate,
    this.scheduledAt,
    required this.entries,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      /// 🔥 SAFE id
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,

      /// 🔥 SAFE card id
      card: json['card'] is int
          ? json['card']
          : int.tryParse(json['card']?.toString() ?? '') ?? 0,

      /// 🔥 SAFE nested objects
      cardData: json['card_data'] is Map<String, dynamic>
          ? CardModel.fromJson(json['card_data'])
          : null,

      customerData: json['customer_data'] is Map<String, dynamic>
          ? CustomerModel.fromJson(json['customer_data'])
          : null,

      /// 🔥 SAFE strings
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? '',
      visitType: json['visit_type']?.toString() ?? '',
      preferredDate: json['preferred_date']?.toString() ?? '',
      scheduledAt: json['scheduled_at']?.toString(),

      /// 🔥 SAFE entries
      entries: (json['entries'] is List)
          ? (json['entries'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => ServiceEntryModel.fromJson(e))
              .toList()
          : [],
    );
  }

  // ============================
  // Helpers (UI-safe)
  // ============================

  String get customerName => customerData?.name ?? '-';
  String get customerPhone => customerData?.phone ?? '-';

  String get cardModel => cardData?.model ?? '-';
  String get cardType => cardData?.cardType ?? '-';

  String get address =>
      cardData == null ? 'Address not available' : cardData!.fullAddress;

  bool get awaitingOtp => status == 'awaiting_otp';
  bool get completed => status == 'completed';
}
