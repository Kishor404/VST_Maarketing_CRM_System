class ServiceEntryModel {
  final int id;
  final String actualComplaint;
  final String visitType;
  final String workDetail;

  /// JSONField → dynamic list
  final List<Map<String, dynamic>> partsReplaced;

  final double? amountCharged;
  final DateTime createdAt;

  ServiceEntryModel({
    required this.id,
    required this.actualComplaint,
    required this.visitType,
    required this.workDetail,
    required this.partsReplaced,
    this.amountCharged,
    required this.createdAt,
  });

  factory ServiceEntryModel.fromJson(Map<String, dynamic> json) {
    return ServiceEntryModel(
      id: json['id'],
      actualComplaint: json['actual_complaint'] ?? '',
      visitType: json['visit_type'] ?? 'onsite',
      workDetail: json['work_detail'] ?? '',

      /// SAFE JSON PARSE
      partsReplaced: (json['parts_replaced'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [],

      amountCharged: json['amount_charged'] != null
          ? double.tryParse(json['amount_charged'].toString())
          : null,

      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
