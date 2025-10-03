import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:manna_donate_app/core/cache_invalidation_manager.dart';

import 'env.dart';
import 'error_handler.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late final Dio _dio;
  late final FlutterSecureStorage _storage;
  late final Logger _logger;
  
  // Flags to prevent multiple operations
  static bool _isLoggingOut = false;
  static bool _isPlaidLinking = false;
  static bool _isRefreshingToken = false;
  
  // Callback for auth errors
  static Function()? onAuthError;
  static Function()? onNetworkError;
  
  // Connectivity stream
  late Stream<ConnectivityResult> _connectivityStream;
  bool _isConnected = true;

  static bool get isPlaidLinking => _isPlaidLinking;
  static bool get isConnected => _instance._isConnected;
  
  ApiService._internal() {
    _storage = const FlutterSecureStorage();
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
    
    _initializeDio();
    _initializeConnectivity();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60), // Increased from 30s
      receiveTimeout: const Duration(seconds: 120), // Increased from 30s  
      sendTimeout: const Duration(seconds: 60), // Increased from 30s
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'MannaApp/2.0.0',
      },
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ));

    // Add interceptors
    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _LoggingInterceptor(_logger),
      _ErrorInterceptor(),
      _RetryInterceptor(),
    ]);
  }

  void _initializeConnectivity() {
    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((ConnectivityResult result) {
      _isConnected = result != ConnectivityResult.none;
      if (!_isConnected && onNetworkError != null) {
        onNetworkError!();
      }
    });
  }

  // Token management
  Future<String?> get accessToken async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> get refreshToken async {
    return await _storage.read(key: 'refresh_token');
  }

  // Getters for other services
  Dio get client => _dio;
  FlutterSecureStorage get storage => _storage;

  // Get user ID from storage
  Future<String?> getUserId() async {
    final userStr = await _storage.read(key: 'user');
    if (userStr != null) {
      final user = jsonDecode(userStr);
      return user['id']?.toString();
    }
    return null;
  }

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  // HTTP methods with proper error handling
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (!_isConnected) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
          type: DioExceptionType.connectionError,
        );
      }

      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _logger.e('GET request failed: $path', error: e);
      rethrow;
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (!_isConnected) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
          type: DioExceptionType.connectionError,
        );
      }

      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      // Invalidate cache after successful POST request
      if (response.statusCode == 200 || response.statusCode == 201) {
        _invalidateCacheAfterRequest(path, data);
      }

      return response;
    } catch (e) {
      _logger.e('POST request failed: $path', error: e);
      rethrow;
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      if (!_isConnected) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
          type: DioExceptionType.connectionError,
        );
      }

      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      // Invalidate cache after successful PUT request
      if (response.statusCode == 200 || response.statusCode == 204) {
        _invalidateCacheAfterRequest(path, data);
      }

      return response;
    } catch (e) {
      _logger.e('PUT request failed: $path', error: e);
      rethrow;
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      if (!_isConnected) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
          type: DioExceptionType.connectionError,
        );
      }

      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      // Invalidate cache after successful DELETE request
      if (response.statusCode == 200 || response.statusCode == 204) {
        _invalidateCacheAfterRequest(path, data);
      }

      return response;
    } catch (e) {
      _logger.e('DELETE request failed: $path', error: e);
      rethrow;
    }
  }

  // File upload
  Future<Response<T>> uploadFile<T>(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? extraData,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      if (!_isConnected) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
          type: DioExceptionType.connectionError,
        );
      }

      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(file.path),
        ...?extraData,
      });

      final response = await _dio.post<T>(
        path,
        data: formData,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );

      // Invalidate cache after successful file upload
      if (response.statusCode == 200 || response.statusCode == 201) {
        _invalidateCacheAfterRequest(path, formData);
      }

      return response;
    } catch (e) {
      _logger.e('File upload failed: $path', error: e);
      rethrow;
    }
  }

  // Set up auth error handler with AuthProvider
  static void setupAuthErrorHandler(Function() authErrorHandler) {
    onAuthError = authErrorHandler;
  }

  // Token refresh - coordinated with AuthProvider
  Future<bool> refreshAccessToken() async {
    if (_isRefreshingToken) {
      // Wait for ongoing refresh to complete
      while (_isRefreshingToken) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return true;
    }
    
    _isRefreshingToken = true;
    
    try {
      final refreshToken = await this.refreshToken;
      if (refreshToken == null) {
        _isRefreshingToken = false;
        return false;
      }

      final response = await post('/mobile/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final tokens = data['data']['tokens'];
        
        await setTokens(
          accessToken: tokens['access_token'],
          refreshToken: tokens['refresh_token'],
        );
        
        _isRefreshingToken = false;
        return true;
      }
    } catch (e) {
      _logger.e('Token refresh failed', error: e);
      await clearTokens();
      if (onAuthError != null) {
        onAuthError!();
      }
    }
    
    _isRefreshingToken = false;
    return false;
  }

  // Logout
  Future<void> logout() async {
    if (_isLoggingOut) return;
    
    _isLoggingOut = true;
    
    try {
      // Use a shorter timeout for logout
      await _dio.post(
        '/mobile/auth/logout',
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _logger.e('Logout request failed', error: e);
      // Continue with cleanup even if API fails
    } finally {
      await clearTokens();
      _isLoggingOut = false;
    }
  }

  // Set Plaid linking flag
  static void setPlaidLinking(bool value) {
    _isPlaidLinking = value;
  }

  // Dispose
  void dispose() {
    _dio.close();
  }

  /// Helper method to invalidate cache after successful POST/PUT/DELETE requests
  void _invalidateCacheAfterRequest(String path, dynamic data) {
    try {
      // Convert data to Map if possible
      Map<String, dynamic>? requestData;
      if (data is Map<String, dynamic>) {
        requestData = data;
      } else if (data is FormData) {
        // Extract data from FormData
        requestData = <String, dynamic>{};
        for (final field in data.fields) {
          requestData[field.key] = field.value;
        }
      }

      // Trigger cache invalidation in background
      Future.microtask(() async {
        try {
          await CacheInvalidationManager.invalidateAndRefreshCache(path, requestData: requestData);
        } catch (e) {
          _logger.e('Cache invalidation failed for $path: $e');
        }
      });
    } catch (e) {
      _logger.e('Error preparing cache invalidation for $path: $e');
    }
  }
}

// Auth Interceptor
class _AuthInterceptor extends Interceptor {
  final Logger _logger = Logger();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await const FlutterSecureStorage().read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
        
    // Set Plaid linking flag for bank operations
    if (options.path.contains('/mobile/bank/link-token') || 
        options.path.contains('/mobile/bank/exchange-token')) {
      ApiService.setPlaidLinking(true);
    }
    
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 errors for non-auth endpoints
    if (err.response?.statusCode == 401 && 
        !err.requestOptions.path.contains('/mobile/auth/refresh') &&
        !err.requestOptions.path.contains('/mobile/auth/login') &&
        !err.requestOptions.path.contains('/mobile/auth/register')) {
      
      _logger.w('401 error detected, attempting token refresh');
      
      // Try to refresh token
      final refreshed = await ApiService().refreshAccessToken();
      if (refreshed) {
        // Retry the original request with new token
        final token = await const FlutterSecureStorage().read(key: 'access_token');
        if (token != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          
          try {
            final response = await ApiService()._dio.fetch(err.requestOptions);
            handler.resolve(response);
            return;
          } catch (e) {
            // If retry fails, proceed with logout
            _logger.e('Request retry failed after token refresh', error: e);
          }
        }
      }
      
      // If refresh fails or retry fails, trigger logout
      _logger.w('Token refresh failed, triggering logout');
      if (ApiService.onAuthError != null) {
        ApiService.onAuthError!();
      }
    }
    
    handler.next(err);
  }
}

// Logging Interceptor
class _LoggingInterceptor extends Interceptor {
  final Logger _logger;

  _LoggingInterceptor(this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i('REQUEST[${options.method}] => PATH: ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    handler.next(err);
  }
}

// Error Interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Use the new error handler for consistent error messages
    final errorMessage = ErrorHandler.getErrorMessage(err);
    err = err.copyWith(error: errorMessage);
    
    handler.next(err);
  }
}

// Retry Interceptor
class _RetryInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      // Retry up to 3 times for connection errors
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          // Check connectivity before retrying
          final connectivityResult = await Connectivity().checkConnectivity();
          if (connectivityResult == ConnectivityResult.none) {
            // No internet connection, don't retry
            break;
          }
          
          // Wait with exponential backoff
          await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
          
          // Create a new request options with longer timeout for retries
          final retryOptions = err.requestOptions.copyWith(
            receiveTimeout: const Duration(seconds: 180), // 3 minutes for retries
            connectTimeout: const Duration(seconds: 90),
          );
          
          final response = await ApiService()._dio.fetch(retryOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            break;
          }
        }
      }
    }
    
    // If all retries failed and it's a timeout/connection error, 
    // try to serve cached data if available
    if ((err.type == DioExceptionType.connectionError ||
         err.type == DioExceptionType.connectionTimeout ||
         err.type == DioExceptionType.receiveTimeout) &&
        err.requestOptions.method == 'GET') {
      
      // Log the fallback attempt
      Logger().w('All retries failed for ${err.requestOptions.path}, attempting to serve cached data');
    }
    
    handler.next(err);
  }
} 