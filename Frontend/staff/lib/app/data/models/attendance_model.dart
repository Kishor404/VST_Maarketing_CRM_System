class AttendanceModel {
  final String date;
  final String? status;

  AttendanceModel({
    required this.date,
    this.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      date: json['date'],
      status: json['status'],
    );
  }
}
