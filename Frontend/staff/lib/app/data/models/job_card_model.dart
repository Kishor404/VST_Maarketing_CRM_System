import '../../core/constants/app_constants.dart';

class JobCardModel {
  final int id;
  final int serviceId;

  final String partName;
  final String details;
  final String? imageUrl;
  final String status;

  final String? staffName;
  final String? reinstallStaffName;

  JobCardModel({
    required this.id,
    required this.serviceId,
    required this.partName,
    required this.details,
    this.imageUrl,
    required this.status,
    this.staffName,
    this.reinstallStaffName,
  });

  factory JobCardModel.fromJson(Map<String, dynamic> json) {
    return JobCardModel(
      id: json['id'] ?? 0,
      serviceId: json['service'] ?? 0,

      partName: json['part_name'] ?? '',
      details: json['details'] ?? '',
      imageUrl: json['image'],
      status: json['status'] ?? '',

      staffName: json['staff_name'],
      reinstallStaffName: json['reinstall_staff_name'],
    );
  }

  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;

    if (imageUrl!.startsWith('http')) return imageUrl;

    return "${AppConstants.baseUrl}$imageUrl";
  }

  bool get isRepairCompleted => status == "repair_completed";
  bool get isReinstalled => status == "reinstalled";
}
