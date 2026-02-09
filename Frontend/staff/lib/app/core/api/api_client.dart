import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'api_endpoints.dart';
import 'api_exceptions.dart';
import '../constants/app_constants.dart';
import '../constants/storage_keys.dart';
import '../../routes/app_routes.dart';

class ApiClient {
  late final Dio _dio;
  final GetStorage _storage = GetStorage();

  bool _isRefreshing = false;
  final List<Completer<void>> _refreshQueue = [];

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout:
            Duration(seconds: AppConstants.connectTimeout),
        receiveTimeout:
            Duration(seconds: AppConstants.receiveTimeout),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  // ============================
  // Request Interceptor
  // ============================

  void _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = _storage.read(StorageKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ============================
  // Error Interceptor (JWT Refresh)
  // ============================

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      final requestOptions = error.requestOptions;

      // Refresh token itself failed → logout
      if (requestOptions.path == ApiEndpoints.refreshToken) {
        _forceLogout();
        return handler.reject(error);
      }

      try {
        await _refreshAccessToken();

        requestOptions.headers['Authorization'] =
            'Bearer ${_storage.read(StorageKeys.accessToken)}';

        final response = await _dio.fetch(requestOptions);
        return handler.resolve(response);
      } catch (_) {
        _forceLogout();
      }
    }

    handler.reject(error);
  }

  // ============================
  // Token Refresh Logic
  // ============================

  Future<void> _refreshAccessToken() async {
    if (_isRefreshing) {
      final c = Completer<void>();
      _refreshQueue.add(c);
      return c.future;
    }

    _isRefreshing = true;

    try {
      final refresh = _storage.read(StorageKeys.refreshToken);
      if (refresh == null) {
        throw ApiException('No refresh token');
      }

      final res = await Dio().post(
        AppConstants.baseUrl + ApiEndpoints.refreshToken,
        data: {"refresh": refresh},
      );

      _storage.write(
        StorageKeys.accessToken,
        res.data['access'],
      );

      for (final c in _refreshQueue) {
        c.complete();
      }
      _refreshQueue.clear();
    } finally {
      _isRefreshing = false;
    }
  }

  // ============================
  // SAFE HTTP HELPERS
  // ============================

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    bool isMultipart = false,
  }) async {
    try {
      final res = await _dio.post(
        path,
        data: data,
        options: Options(
          contentType: isMultipart
              ? 'multipart/form-data'
              : 'application/json',
        ),
      );
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }


  Future<dynamic> patch(
    String path, {
    dynamic data,
    bool isMultipart = false,
  }) async {
    try {
      final res = await _dio.patch(
        path,
        data: data,
        options: Options(
          contentType: isMultipart
              ? 'multipart/form-data'
              : 'application/json',
        ),
      );
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }


  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ============================
  // Force Logout
  // ============================

  void _forceLogout() {
    _storage.erase();
    Get.offAllNamed(AppRoutes.login);
  }
}
