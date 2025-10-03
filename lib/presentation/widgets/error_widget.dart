import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manna_donate_app/core/error_handler.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';

class AppErrorWidget extends StatelessWidget {
  final String? error;
  final DioException? dioError;
  final VoidCallback? onRetry;
  final String? retryText;
  final bool showIcon;
  final bool compact;

  const AppErrorWidget({
    super.key,
    this.error,
    this.dioError,
    this.onRetry,
    this.retryText,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorMessage = _getErrorMessage();
    final errorIcon = _getErrorIcon();
    final errorColor = _getErrorColor(isDark);

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: errorColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (showIcon) ...[
              Icon(errorIcon, color: errorColor, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                errorMessage,
                style: AppTextStyles.getBody(
                  isDark: isDark,
                ).copyWith(color: errorColor, fontSize: 14),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  retryText ?? 'Retry',
                  style: AppTextStyles.getBodySmall(
                    isDark: isDark,
                  ).copyWith(color: errorColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showIcon) ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(errorIcon, size: 40, color: errorColor),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              _getErrorTitle(),
              style: AppTextStyles.getTitle(
                isDark: isDark,
              ).copyWith(color: errorColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: AppTextStyles.getBody(isDark: isDark).copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 40.sp,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryText ?? 'Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getErrorMessage() {
    if (dioError != null) {
      return ErrorHandler.getErrorMessage(dioError!);
    }
    return error ?? 'An unexpected error occurred';
  }

  String _getErrorTitle() {
    if (dioError != null) {
      if (ErrorHandler.isNetworkError(dioError!)) {
        return 'No Internet Connection';
      } else if (ErrorHandler.isServerError(dioError!)) {
        return 'Server Unavailable';
      } else if (ErrorHandler.isNoServerResponse(dioError!)) {
        return 'No Server Response';
      }
    }
    return 'Something went wrong';
  }

  IconData _getErrorIcon() {
    if (dioError != null) {
      return ErrorHandler.getErrorIcon(dioError!);
    }
    return Icons.error_outline;
  }

  Color _getErrorColor(bool isDark) {
    if (dioError != null) {
      return ErrorHandler.getErrorColor(dioError!, isDark);
    }
    return isDark ? Colors.red[300]! : Colors.red[600]!;
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;

  const NetworkErrorWidget({super.key, this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off, size: 40, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            Text(
              'No Internet Connection',
              style: AppTextStyles.getTitle(
                isDark: isDark,
              ).copyWith(color: Colors.orange, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'Please check your internet connection and try again.',
              style: AppTextStyles.getBody(isDark: isDark).copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;

  const ServerErrorWidget({super.key, this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 24),
            Text(
              'Server Unavailable',
              style: AppTextStyles.getTitle(
                isDark: isDark,
              ).copyWith(color: Colors.red, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message ??
                  'Our servers are temporarily unavailable. Please try again later.',
              style: AppTextStyles.getBody(isDark: isDark).copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 40.sp,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
