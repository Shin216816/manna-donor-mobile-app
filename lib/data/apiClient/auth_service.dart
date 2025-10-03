import 'package:dio/dio.dart';
import 'package:manna_donate_app/core/api_service.dart';
import 'package:manna_donate_app/data/models/api_response.dart';
import 'dart:io';

class AuthService {
  final ApiService _api = ApiService();

  /// Register a new user
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
    String? middleName,
    String? phone,
  }) async {
    // Build request data matching backend schema
    final requestData = {
      'first_name': firstName,
      'password': password,
      if (lastName != null) 'last_name': lastName,
      if (middleName != null) 'middle_name': middleName,
      if (phone != null) 'phone': phone,
    };

    // Add email or phone (backend requires at least one)
    if (email.isNotEmpty) {
      requestData['email'] = email;
    } else if (phone != null && phone.isNotEmpty) {
      requestData['phone'] = phone;
    } else {
      return ApiResponse(
        success: false,
        message: 'Either email or phone is required',
      );
    }

    try {
      final response = await _api.post('/mobile/auth/register', data: requestData);

      // Registration returns verification data
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Registration failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Registration failed: $e');
    }
  }

  /// Verify email or phone with OTP
  Future<ApiResponse<Map<String, dynamic>>> verify(
    String email,
    String code, {
    String? phone,
  }) async {
    try {
      final data = <String, dynamic>{
        'access_code': code,
      };
      
      if (email.isNotEmpty) {
        data['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        data['phone'] = phone;
      }

      final response = await _api.post(
        '/mobile/auth/register/confirm',
        data: data,
      );

      // Parse tokens and user from response schema
      return ApiResponse.fromJson(response.data, (data) {
        return {'tokens': data['tokens'], 'user': data['user']};
      });
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Verification failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Verification failed: $e');
    }
  }

  /// Resend verification code
  Future<ApiResponse<Map<String, dynamic>>> resendCode(String email, {String? phone}) async {
    try {
      final data = <String, dynamic>{};
      if (email.isNotEmpty) {
        data['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        data['phone'] = phone;
      }
      
      final response = await _api.post(
        '/mobile/auth/register/resend-code',
        data: data,
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to resend code: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to resend code: $e');
    }
  }

  /// Login with email/phone and password
  Future<ApiResponse<Map<String, dynamic>>> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    try {
      final data = <String, dynamic>{
        'password': password,
      };
      
      if (email != null && email.isNotEmpty) {
        data['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        data['phone'] = phone;
      }

      final response = await _api.post(
        '/mobile/auth/login',
        data: data,
      );

      // Parse tokens and user from response schema
      return ApiResponse.fromJson(response.data, (data) {
        return {'tokens': data['tokens'], 'user': data['user']};
      });
    } on DioException catch (e) {
      // Handle HTTP errors (like 401, 400, etc.)
      if (e.response?.data != null) {
        // Parse the error response from the server
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          return ApiResponse.fromJson(errorData, (data) => data);
        }
      }
      
      // Fallback error message
      return ApiResponse(
        success: false, 
        message: e.response?.data?['detail'] ?? e.message ?? 'Login failed'
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Login failed: $e');
    }
  }

  /// Google OAuth login
  Future<ApiResponse<Map<String, dynamic>>> signInWithGoogle(
    String idToken,
  ) async {
    try {
      // Validate ID token is not empty
      if (idToken.isEmpty) {
        return ApiResponse(
          success: false,
          message: 'Invalid Google ID token provided',
        );
      }

      final response = await _api.post(
        '/mobile/auth/google',
        data: {'id_token': idToken},
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Google sign-in failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Google sign-in failed: $e');
    }
  }

  /// Apple OAuth login
  Future<ApiResponse<Map<String, dynamic>>> signInWithApple(
    String identityToken,
  ) async {
    try {
      final response = await _api.post(
        '/mobile/auth/apple',
        data: {
          'auth_code': identityToken,
        }, // Send identity_token as auth_code parameter
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Apple sign-in failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Apple sign-in failed: $e');
    }
  }

  /// Refresh access token
  Future<ApiResponse<Map<String, dynamic>>> refreshToken(
    String refreshToken,
  ) async {
    try {
      final response = await _api.post(
        '/mobile/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Token refresh failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Token refresh failed: $e');
    }
  }

  /// Forgot password
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({String? email, String? phone}) async {
    try {
      final data = <String, dynamic>{};
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      
      final response = await _api.post(
        '/mobile/auth/forgot-password',
        data: data,
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Forgot password failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Forgot password failed: $e');
    }
  }

  /// Verify OTP for forgot password
  Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    String? email,
    String? phone,
    required String accessCode,
  }) async {
    try {
      final data = <String, dynamic>{
        'access_code': accessCode,
      };
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      
      final response = await _api.post(
        '/mobile/auth/verify-otp',
        data: data,
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'OTP verification failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'OTP verification failed: $e',
      );
    }
  }

  /// Reset password
  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    String? email,
    String? phone,
    required String accessCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final data = <String, dynamic>{
        'access_code': accessCode,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      };
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      
      final response = await _api.post(
        '/mobile/auth/reset-password',
        data: data,
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Reset password failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Reset password failed: $e');
    }
  }

  /// Change password
  Future<ApiResponse<Map<String, dynamic>>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _api.post(
        '/mobile/auth/change-password',
        data: {
          'old_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': newPassword,
        },
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Change password failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Change password failed: $e');
    }
  }

  /// Get current user data
  Future<ApiResponse<Map<String, dynamic>>> getMe() async {
    try {
      final response = await _api.get('/mobile/auth/me');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get user data: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get user data: $e',
      );
    }
  }

  /// Get current user profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    try {
      final response = await _api.get('/mobile/auth/me');
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

  /// Update profile
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    String? avatar,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['first_name'] = firstName;
      if (middleName != null) data['middle_name'] = middleName;
      if (lastName != null) data['last_name'] = lastName;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (avatar != null) data['avatar'] = avatar;

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
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _api.post('/mobile/profile/image', data: formData);
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Upload profile image failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Upload profile image failed: $e');
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
      return ApiResponse(success: false, message: 'Remove profile image failed: $e');
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
      return ApiResponse(success: false, message: 'Get profile image failed: $e');
    }
  }

  /// Send email verification code
  Future<ApiResponse<Map<String, dynamic>>> sendEmailVerification() async {
    try {
      final response = await _api.post('/mobile/profile/verify-email/send');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Send email verification failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Send email verification failed: $e');
    }
  }

  /// Confirm email verification
  Future<ApiResponse<Map<String, dynamic>>> confirmEmailVerification(String code, String email) async {
    try {
      final response = await _api.post('/mobile/profile/verify-email/confirm', data: {
        'access_code': code,
        'email': email,
      });
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Confirm email verification failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Confirm email verification failed: $e');
    }
  }

  /// Send phone verification code
  Future<ApiResponse<Map<String, dynamic>>> sendPhoneVerification() async {
    try {
      final response = await _api.post('/mobile/profile/verify-phone/send');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Send phone verification failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Send phone verification failed: $e');
    }
  }

  /// Confirm phone verification
  Future<ApiResponse<Map<String, dynamic>>> confirmPhoneVerification(String code, String phone) async {
    try {
      final response = await _api.post('/mobile/profile/verify-phone/confirm', data: {
        'access_code': code,
        'phone': phone,
      });
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Confirm phone verification failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Confirm phone verification failed: $e');
    }
  }

  /// Google sign in (alias for signInWithGoogle)
  Future<ApiResponse<Map<String, dynamic>>> googleSignIn(
    String idToken,
  ) async {
    return signInWithGoogle(idToken);
  }

  /// Apple sign in (alias for signInWithApple)
  Future<ApiResponse<Map<String, dynamic>>> appleSignIn(
    String identityToken,
    String authorizationCode,
  ) async {
    return signInWithApple(identityToken);
  }

  /// Verify email
  Future<ApiResponse<Map<String, dynamic>>> verifyEmail(
    String email,
    String otp,
  ) async {
    try {
      final response = await _api.post(
        '/mobile/auth/verify-otp',
        data: {'email': email, 'access_code': otp},
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Verify email failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Verify email failed: $e');
    }
  }

  /// Resend verification
  Future<ApiResponse<Map<String, dynamic>>> resendVerification() async {
    try {
      final response = await _api.post('/mobile/auth/resend-verification');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Resend verification failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Resend verification failed: $e',
      );
    }
  }

  /// Verify PIN
  Future<ApiResponse<Map<String, dynamic>>> verifyPin(String pin) async {
    try {
      final response = await _api.post('/mobile/auth/verify-pin', data: {'pin': pin});
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Verify PIN failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Verify PIN failed: $e');
    }
  }

  /// Get terms of service
  Future<ApiResponse<Map<String, dynamic>>> getTermsOfService() async {
    try {
      final response = await _api.get('/mobile/legal/terms');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Get terms of service failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Get terms of service failed: $e',
      );
    }
  }

  /// Get privacy policy
  Future<ApiResponse<Map<String, dynamic>>> getPrivacyPolicy() async {
    try {
      final response = await _api.get('/mobile/legal/privacy');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Get privacy policy failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Get privacy policy failed: $e',
      );
    }
  }

  /// Logout user
  Future<ApiResponse<Map<String, dynamic>>> logout(
    String? token,
    String? refreshToken,
  ) async {
    try {
      final response = await _api.post(
        '/mobile/auth/logout',
        data: {
          if (token != null) 'token': token,
          if (refreshToken != null) 'refresh_token': refreshToken,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Logout failed: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Logout failed: $e');
    }
  }
}
