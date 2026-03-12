class PartReplacedModel {
  final String name;
  final String? serialNumber;

  PartReplacedModel({
    required this.name,
    this.serialNumber,
  });

  factory PartReplacedModel.fromJson(Map<String, dynamic> json) {
    return PartReplacedModel(
      name: json['name'] ?? '',
      serialNumber: json['serial_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "serial_number": serialNumber,
    };
  }
}

class ServiceEntryModel {
  final int id;
  final int? performedBy;
  final String actualComplaint;
  final String visitType;
  final String workDetail;
  final List<PartReplacedModel>? partsReplaced;
  final String amountCharged;
  final DateTime createdAt;
  final int service;

  ServiceEntryModel({
    required this.id,
    this.performedBy,
    required this.actualComplaint,
    required this.visitType,
    required this.workDetail,
    this.partsReplaced,
    required this.amountCharged,
    required this.createdAt,
    required this.service,
  });

  factory ServiceEntryModel.fromJson(Map<String, dynamic> json) {
    return ServiceEntryModel(
      id: json['id'],
      performedBy: json['performed_by'],
      actualComplaint: json['actual_complaint'] ?? '',
      visitType: json['visit_type'] ?? '',
      workDetail: json['work_detail'] ?? '',
      partsReplaced: json['parts_replaced'] is List
        ? (json['parts_replaced'] as List)
            .map((e) => PartReplacedModel.fromJson(e))
            .toList()
        : null,
      amountCharged: json['amount_charged'] ?? '0.00',
      createdAt: DateTime.parse(json['created_at']),
      service: json['service'],
    );
  }
}
