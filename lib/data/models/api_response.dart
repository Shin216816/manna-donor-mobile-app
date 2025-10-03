class ApiResponse<T> {
  /// Indicates if the operation was successful
  final bool success;
  /// Response message
  final String message;
  /// Response data (can be null)
  final T? data;
  /// Error code for client handling (snake_case)
  final String? errorCode;
  /// Additional error details (for error responses)
  final Map<String, dynamic>? details;
  /// Unique request identifier
  final String? requestId;
  /// Response timestamp (ISO8601 string)
  final String? timestamp;
  /// Pagination metadata (for paginated responses)
  final Map<String, dynamic>? pagination;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
    this.details,
    this.requestId,
    this.timestamp,
    this.pagination,
  });

  /// Parse ApiResponse from JSON, matching backend schema
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, T Function(dynamic) fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromData(json['data']) : null,
      errorCode: json['error_code'],
      details: json['details'] != null ? Map<String, dynamic>.from(json['details']) : null,
      requestId: json['request_id'],
      timestamp: json['timestamp'],
      pagination: json['pagination'] != null ? Map<String, dynamic>.from(json['pagination']) : null,
    );
  }

  static String userFriendlyMessage(String? errorCode, String fallback) {
    switch (errorCode) {
      // Authentication errors - these should trigger immediate logout
      case 'AUTH.TOKEN.INVALID':
        return 'Your session has expired. Please log in again.';
      case 'AUTH.TOKEN.REVOKED':
        return 'Your session has been revoked. Please log in again.';
      case 'AUTH.ADMIN.TOKEN.INVALID':
        return 'Your admin session has expired. Please log in again.';
      case 'AUTH.ROLE.FORBIDDEN':
        return 'You do not have permission to access this resource.';
      case 'REFRESH_TOKEN.INVALID_OR_EXPIRED':
        return 'Your session has expired. Please log in again.';
      
      // Login errors
      case 'LOGIN_FAILED':
        return 'Invalid email or password.';
      case 'EMAIL_EXISTS':
        return 'This email is already registered.';
      case 'USER_NOT_FOUND':
        return 'User not found.';
      case 'INVALID_CODE':
        return 'The code you entered is invalid or expired.';
      case 'REGISTER_ACCESS_CODE_INVALID':
        return 'The verification code you entered is invalid. Please check and try again.';
      case 'REGISTER_ACCESS_CODE_EXPIRED':
        return 'The verification code has expired (120 seconds). Please request a new code.';
      case 'PASSWORDS_DO_NOT_MATCH':
        return 'Passwords do not match.';
      case 'OLD_PASSWORD.INVALID':
        return 'Current password is incorrect.';
      case 'PASSWORD.MISMATCH':
        return 'New password and confirm password do not match.';
      case 'PASSWORD.CHANGE.DB_ERROR':
        return 'Failed to change password due to a database error. Please try again.';
      case 'PASSWORD.CHANGE.ERROR':
        return 'Failed to change password. Please try again.';
      case 'USER.NOT_FOUND':
        return 'User not found. Please check your email address.';
      case 'VERIFY_OTP.DB_ERROR':
        return 'Failed to verify code due to a database error. Please try again.';
      case 'VERIFY_OTP.ERROR':
        return 'Failed to verify code. Please try again.';
      
      // Business logic errors
      case 'BANK_ACCOUNT_EXISTS':
        return 'This bank account is already linked.';
      case 'BANK_ACCOUNT_NOT_FOUND':
        return 'Bank account not found.';
      case 'CHURCH_NOT_FOUND':
        return 'Church not found.';
      case 'FORBIDDEN':
        return 'You are not authorized to perform this action.';
      case 'SERVER_ERROR':
        return 'Something went wrong. Please try again later.';
      default:
        return fallback.isNotEmpty ? fallback : 'An error occurred.';
    }
  }
} 