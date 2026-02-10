import '../../core/constants/app_constants.dart';

class JobCardModel {
  /// ============================
  /// CORE FIELDS
  /// ============================
  final int id;
  final int serviceId;

  final String partName;
  final String details;
  final String status;

  /// ============================
  /// STAFF INFO
  /// ============================
  final String? staffName;
  final String? reinstallStaffName;
  final int? reinstallStaffId;

  /// ============================
  /// IMAGE
  /// ============================
  final String? imageUrl;

  /// ============================
  /// TIMESTAMPS (OPTIONAL)
  /// ============================
  final String? createdAt;
  final String? repairCompletedAt;
  final String? reinstalledAt;

  JobCardModel({
    required this.id,
    required this.serviceId,
    required this.partName,
    required this.details,
    required this.status,

    this.staffName,
    this.reinstallStaffName,
    this.reinstallStaffId,

    this.imageUrl,

    this.createdAt,
    this.repairCompletedAt,
    this.reinstalledAt,
  });

  /// ============================
  /// JSON PARSER
  /// ============================

  factory JobCardModel.fromJson(Map<String, dynamic> json) {
    return JobCardModel(
      id: json['id'] ?? 0,

      /// backend sends `service_id`
      serviceId: json['service_id'] ?? json['service'] ?? 0,

      partName: json['part_name'] ?? '',
      details: json['details'] ?? '',
      status: json['status'] ?? '',

      staffName: json['staff_name'],
      reinstallStaffName: json['reinstall_staff_name'],
      reinstallStaffId: json['reinstall_staff'],

      imageUrl: json['image'],

      createdAt: json['created_at'],
      repairCompletedAt: json['repair_completed_at'],
      reinstalledAt: json['reinstalled_at'],
    );
  }

  /// ============================
  /// FULL IMAGE URL ⭐
  /// ============================

  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;

    if (imageUrl!.startsWith('http')) {
      return imageUrl;
    }

    return "${AppConstants.baseUrl}$imageUrl";
  }

  /// ============================
  /// STATUS HELPERS
  /// ============================

  bool get isRepairCompleted => status == "repair_completed";

  bool get isReinstalled => status == "reinstalled";

  bool get canReinstall =>
      status == "repair_completed" && reinstallStaffId != null;
}
