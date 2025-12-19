import 'package:dio/dio.dart';

/// Unified API exception handler
/// Converts Dio errors into readable messages

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  factory ApiException.fromDio(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;

      if (data is Map<String, dynamic>) {
        if (data['detail'] != null) {
          return ApiException(data['detail'].toString());
        }
        if (data['message'] != null) {
          return ApiException(data['message'].toString());
        }
      }

      return ApiException(
        'Server error (${e.response?.statusCode})',
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException('Connection timeout');
    }

    if (e.type == DioExceptionType.connectionError) {
      return ApiException('No internet connection');
    }

    return ApiException('Unexpected error occurred');
  }

  @override
  String toString() => message;
}
