class AppConstants {
  AppConstants._();

  /// Base URL of Django backend
  /// 🔧 Change this based on environment
  ///
  /// Local (emulator):
  /// http://10.0.2.2:8000
  ///
  /// Local (real device):
  /// http://<YOUR_IP>:8000
  ///
  /// Production:
  /// https://api.vstmaarketing.com
  static const String baseUrl = 'http://157.173.220.208';

  /// API timeout values (seconds)
  static const int connectTimeout = 15;
  static const int receiveTimeout = 15;

  /// App info
  static const String appName = 'VST Maarketing';

  /// Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  /// Pagination (future use)
  static const int defaultPageSize = 20;
}
