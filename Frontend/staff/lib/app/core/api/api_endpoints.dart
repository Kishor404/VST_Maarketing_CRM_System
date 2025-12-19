import '../constants/app_constants.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = AppConstants.baseUrl;

  static const String login = '/api/auth/login/';
  static const String refreshToken = '/api/auth/token/refresh/';
  static const String myProfile = '/api/auth/me/';

  static const String services = '/api/crm/services/';
  static String serviceDetail(int id) =>
      '/api/crm/services/$id/';

  static String requestOtp(int id) =>
      '/api/crm/services/$id/request_otp/';
  static String verifyOtp(int id) =>
      '/api/crm/services/$id/verify_otp/';

  static const String serviceEntries =
      '/api/crm/service-entries/';
  static const String feedbacks = '/api/crm/feedbacks/';
  static const String myAttendance =
      '/api/crm/attendance/me/';
}
