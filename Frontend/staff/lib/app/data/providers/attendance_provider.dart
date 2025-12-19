//import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/attendance_model.dart';

class AttendanceProvider {
  final ApiClient _apiClient;

  AttendanceProvider(this._apiClient);

  /// ============================
  /// Get Today Attendance (Staff)
  /// ============================
  ///
  /// GET /api/crm/attendance/me/
  Future<AttendanceModel> getTodayAttendance() async {
    final data =
        await _apiClient.get(ApiEndpoints.myAttendance);

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid attendance response');
    }

    return AttendanceModel.fromJson(data);
  }
}
