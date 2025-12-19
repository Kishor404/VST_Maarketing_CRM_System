import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../constants/app_constants.dart';
import '../../routes/app_routes.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final dio.Dio dioClient;
  final GetStorage _storage = GetStorage();

  ApiClient._internal() {
    dioClient = dio.Dio(
      dio.BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: dio.ResponseType.json,
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  /// -------------------------
  /// INTERCEPTORS
  /// -------------------------
  void _setupInterceptors() {
    dioClient.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.read('access');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },

        onError: (dio.DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final newToken = _storage.read('access');
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';

              final clonedResponse =
                  await dioClient.fetch(error.requestOptions);
              return handler.resolve(clonedResponse);
            } else {
              _forceLogout();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// -------------------------
  /// TOKEN REFRESH
  /// -------------------------
  Future<bool> _refreshToken() async {
    try {
      final refresh = _storage.read('refresh');
      if (refresh == null) return false;

      final response = await dio.Dio().post(
        '${AppConstants.baseUrl}/api/auth/token/refresh/',
        data: {'refresh': refresh},
      );

      _storage.write('access', response.data['access']);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// -------------------------
  /// FORCE LOGOUT
  /// -------------------------
  void _forceLogout() {
    _storage.erase();
    Get.offAllNamed(AppRoutes.LOGIN);
  }

  /// =========================
  /// HTTP HELPERS
  /// =========================

  Future<dio.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dioClient.get(
      path,
      queryParameters: queryParameters,
    );
  }

  Future<dio.Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dioClient.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<dio.Response> patch(
    String path, {
    dynamic data,
  }) async {
    return await dioClient.patch(
      path,
      data: data,
    );
  }

  Future<dio.Response> delete(String path) async {
    return await dioClient.delete(path);
  }
}
