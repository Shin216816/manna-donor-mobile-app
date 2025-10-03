import 'package:dio/dio.dart';
import 'dart:io';

import 'package:manna_donate_app/core/api_service.dart';
import 'package:manna_donate_app/data/models/api_response.dart';

class ProfileService {
  final ApiService _api = ApiService();

  /// Get user profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    try {
      final response = await _api.get('/mobile/profile');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Get profile failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Get profile failed: $e');
    }
  }

  /// Update user profile
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? bio,
    String? timezone,
    String? language,
    String? currency,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (bio != null) data['bio'] = bio;
      if (timezone != null) data['timezone'] = timezone;
      if (language != null) data['language'] = language;
      if (currency != null) data['currency'] = currency;

      final response = await _api.put('/mobile/profile', data: data);
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Update profile failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Update profile failed: $e');
    }
  }

  /// Upload profile image
  Future<ApiResponse<Map<String, dynamic>>> uploadProfileImage(File imageFile) async {
    try {

      if (!await imageFile.exists()) {
        return ApiResponse(
          success: false,
          message: 'Image file does not exist',
        );
      }
      
      // Check file size (max 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        return ApiResponse(
          success: false,
          message: 'Image file is too large (max 10MB)',
        );
      }
      
      // Validate file extension and get MIME type
      final extension = imageFile.path.split('.').last.toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      if (!allowedExtensions.contains(extension)) {
        return ApiResponse(
          success: false,
          message: 'Unsupported image format. Please use JPG, PNG, GIF, or WebP',
        );
      }

      // Get proper MIME type
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Default fallback
      }

      final bytes = await imageFile.readAsBytes();
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: 'profile_image.$extension',
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final response = await _api.post(
        '/mobile/profile/image',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.message ?? 'Upload failed',
        data: e.response?.data,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Upload failed: $e',
        data: null,
      );
    }
  }

  /// Remove profile image
  Future<ApiResponse<Map<String, dynamic>>> removeProfileImage() async {
    try {
      final response = await _api.delete('/mobile/profile/image');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Remove profile image failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Remove profile image failed: $e',
      );
    }
  }

  /// Get profile image
  Future<ApiResponse<Map<String, dynamic>>> getProfileImage() async {
    try {
      final response = await _api.get('/mobile/profile/image');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Get profile image failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Get profile image failed: $e',
      );
    }
  }

  /// Get profile statistics
  Future<ApiResponse<Map<String, dynamic>>> getProfileStats() async {
    try {
      final response = await _api.get('/mobile/auth/profile/stats');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Get profile stats failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Get profile stats failed: $e');
    }
  }

  /// Get profile activity history
  Future<ApiResponse<Map<String, dynamic>>> getProfileActivity({
    int? page,
    int? limit,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _api.get(
        '/mobile/auth/profile/activity',
        queryParameters: queryParams,
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Get profile activity failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Get profile activity failed: $e');
    }
  }

  /// Update profile preferences
  Future<ApiResponse<Map<String, dynamic>>> updatePreferences({
    Map<String, dynamic>? notifications,
    Map<String, dynamic>? privacy,
    Map<String, dynamic>? display,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (notifications != null) data['notifications'] = notifications;
      if (privacy != null) data['privacy'] = privacy;
      if (display != null) data['display'] = display;

      final response = await _api.put('/mobile/auth/profile/preferences', data: data);
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Update preferences failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Update preferences failed: $e');
    }
  }

  /// Get profile preferences
  Future<ApiResponse<Map<String, dynamic>>> getPreferences() async {
    try {
      final response = await _api.get('/mobile/auth/profile/preferences');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Get preferences failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Get preferences failed: $e');
    }
  }

  /// Export profile data
  Future<ApiResponse<Map<String, dynamic>>> exportProfileData({
    String? format,
    List<String>? includeFields,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (format != null) data['format'] = format;
      if (includeFields != null) data['include_fields'] = includeFields;

      final response = await _api.post('/mobile/auth/profile/export', data: data);
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Export profile data failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Export profile data failed: $e');
    }
  }

  /// Delete profile data
  Future<ApiResponse<Map<String, dynamic>>> deleteProfileData({
    List<String>? fields,
    bool? permanent,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fields != null) data['fields'] = fields;
      if (permanent != null) data['permanent'] = permanent;

      final response = await _api.delete('/mobile/auth/profile/data', data: data);
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Delete profile data failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Delete profile data failed: $e');
    }
  }

  /// Verify profile changes
  Future<ApiResponse<Map<String, dynamic>>> verifyProfileChanges({
    required Map<String, dynamic> changes,
  }) async {
    try {
      final response = await _api.post('/mobile/auth/profile/verify', data: changes);
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Verify profile changes failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Verify profile changes failed: $e');
    }
  }

  /// Get profile validation rules
  Future<ApiResponse<Map<String, dynamic>>> getValidationRules() async {
    try {
      final response = await _api.get('/mobile/auth/profile/validation-rules');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Get validation rules failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Get validation rules failed: $e');
    }
  }

  /// Update profile security settings
  Future<ApiResponse<Map<String, dynamic>>> updateSecuritySettings({
    bool? twoFactorEnabled,
    bool? biometricEnabled,
    String? securityQuestions,
    Map<String, dynamic>? deviceSettings,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (twoFactorEnabled != null) data['two_factor_enabled'] = twoFactorEnabled;
      if (biometricEnabled != null) data['biometric_enabled'] = biometricEnabled;
      if (securityQuestions != null) data['security_questions'] = securityQuestions;
      if (deviceSettings != null) data['device_settings'] = deviceSettings;

      final response = await _api.put('/mobile/auth/profile/security', data: data);
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Update security settings failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Update security settings failed: $e');
    }
  }

  /// Get profile security settings
  Future<ApiResponse<Map<String, dynamic>>> getSecuritySettings() async {
    try {
      final response = await _api.get('/mobile/auth/profile/security');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Get security settings failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Get security settings failed: $e');
    }
  }

  /// Request profile data deletion
  Future<ApiResponse<Map<String, dynamic>>> requestDataDeletion({
    String? reason,
    DateTime? scheduledDate,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (reason != null) data['reason'] = reason;
      if (scheduledDate != null) data['scheduled_date'] = scheduledDate.toIso8601String();

      final response = await _api.post('/mobile/auth/profile/deletion-request', data: data);
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Request data deletion failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Request data deletion failed: $e');
    }
  }

  /// Cancel profile data deletion request
  Future<ApiResponse<Map<String, dynamic>>> cancelDataDeletion() async {
    try {
      final response = await _api.delete('/mobile/auth/profile/deletion-request');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Cancel data deletion failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Cancel data deletion failed: $e');
    }
  }
}
