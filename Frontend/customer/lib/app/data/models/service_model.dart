import './service_entry_model.dart';

class ServiceModel {
  final int id;
  final int cardId;

  final String status;
  final String serviceType;
  final String description;

  final DateTime? preferredDate;
  final DateTime? scheduledAt;
  final DateTime createdAt;

  final String visitType;
  final String? assignedToName;
  final String? assignedToPhone;

  final bool isPaid;
  final double? amountCharged;

  final List<ServiceEntryModel> entries;


  /// Feedback
  final bool hasFeedback;
  final int? feedbackRating;
  final String? feedbackComment;

  ServiceModel({
    required this.id,
    required this.cardId,
    required this.status,
    required this.serviceType,
    required this.description,
    this.preferredDate,
    this.scheduledAt,
    required this.createdAt,
    required this.visitType,
    this.assignedToName,
    this.assignedToPhone,
    required this.isPaid,
    this.amountCharged,
    required this.hasFeedback,
    this.feedbackRating,
    this.feedbackComment,
    required this.entries,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final feedback = json['feedback'];

    return ServiceModel(
      id: json['id'],
      cardId: json['card'],

      status: json['status'],
      serviceType: json['service_type'],
      description: json['description'] ?? '',

      preferredDate: json['preferred_date'] != null
          ? DateTime.parse(json['preferred_date'])
          : null,

      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,

      /// Backend provides created_at
      createdAt: DateTime.parse(json['created_at']),

      visitType: json['visit_type'] ?? 'onsite',

      /// Safe nested parsing
      assignedToName: json['assigned_to_detail'] is Map
          ? json['assigned_to_detail']['name']
          : null,

      assignedToPhone: json['assigned_to_detail'] is Map
          ? json['assigned_to_detail']['phone']
          : null,

      isPaid: json['is_paid'] ?? false,

      amountCharged: json['amount_charged'] != null
          ? double.tryParse(json['amount_charged'].toString())
          : null,

      /// Feedback mapping
      hasFeedback: feedback != null,
      feedbackRating: feedback?['rating'],
      feedbackComment: feedback?['comments'],

      entries: (json['entries'] as List? ?? [])
      .map((e) => ServiceEntryModel.fromJson(e))
      .toList(),

    );
  }
}
