import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';

class ErrorHandler {
  static const String _noServerResponse = 'No server response';
  static const String _connectionTimeout = 'Connection timeout';
  static const String _noInternetConnection = 'No internet connection';
  static const String _serverUnavailable = 'Server is temporarily unavailable';
  static const String _unexpectedError = 'An unexpected error occurred';

  /// Get user-friendly error message from DioException
  static String getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
        return _noServerResponse;
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _connectionTimeout;
      case DioExceptionType.badResponse:
        return _getBadResponseMessage(error);
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      default:
        return _unexpectedError;
    }
  }

  /// Get specific error message for bad response
  static String _getBadResponseMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    
    switch (statusCode) {
      case 401:
        return 'Authentication failed. Please log in again.';
      case 403:
        return 'Access denied. You don\'t have permission for this action.';
      case 404:
        return 'Resource not found.';
      case 500:
        return _serverUnavailable;
      case 502:
      case 503:
      case 504:
        return _serverUnavailable;
      default:
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          return data['message'] ?? data['detail'] ?? _unexpectedError;
        }
        return _unexpectedError;
    }
  }

  /// Check if error is a network connectivity issue
  static bool isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
           error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.receiveTimeout;
  }

  /// Check if error is a server issue
  static bool isServerError(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      return statusCode != null && statusCode >= 500;
    }
    return false;
  }

  /// Check if error is a no server response error
  static bool isNoServerResponse(DioException error) {
    return error.type == DioExceptionType.connectionError;
  }

  /// Get retry suggestion based on error type
  static String getRetrySuggestion(DioException error) {
    if (isNetworkError(error)) {
      return 'Please check your internet connection and try again.';
    } else if (isServerError(error)) {
      return 'Server is temporarily unavailable. Please try again later.';
    } else {
      return 'Please try again.';
    }
  }

  /// Get appropriate icon for error type
  static IconData getErrorIcon(DioException error) {
    if (isNetworkError(error)) {
      return Icons.wifi_off;
    } else if (isServerError(error)) {
      return Icons.cloud_off;
    } else {
      return Icons.error_outline;
    }
  }

  /// Get appropriate color for error type
  static Color getErrorColor(DioException error, bool isDark) {
    if (isNetworkError(error)) {
      return Colors.orange;
    } else if (isServerError(error)) {
      return Colors.red;
    } else {
      return isDark ? Colors.red[300]! : Colors.red[600]!;
    }
  }

  /// Handle error with retry logic
  static Future<T?> handleWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
    String? customErrorMessage,
  }) async {
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        return await operation();
      } on DioException catch (e) {
        retryCount++;
        
        // Don't retry for certain error types
        if (e.type == DioExceptionType.cancel || 
            e.type == DioExceptionType.badResponse && e.response?.statusCode == 401) {
          rethrow;
        }
        
        // If it's the last retry, throw the error
        if (retryCount >= maxRetries) {
          throw DioException(
            requestOptions: e.requestOptions,
            type: e.type,
            error: customErrorMessage ?? getErrorMessage(e),
            response: e.response,
          );
        }
        
        // Wait before retrying
        await Future.delayed(delay * retryCount);
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay * retryCount);
      }
    }
    
    throw Exception('Max retries exceeded');
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show network error dialog
  static Future<void> showNetworkErrorDialog(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                'No Internet Connection',
                style: AppTextStyles.getTitle(isDark: isDark).copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Content
              Text(
                'Please check your internet connection and try again.',
                style: AppTextStyles.getBody(isDark: isDark).copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show server error dialog
  static Future<void> showServerErrorDialog(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                'Server Unavailable',
                style: AppTextStyles.getTitle(isDark: isDark).copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Content
              Text(
                'Our servers are temporarily unavailable. Please try again later.',
                style: AppTextStyles.getBody(isDark: isDark).copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
