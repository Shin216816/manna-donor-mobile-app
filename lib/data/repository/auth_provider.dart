import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:manna_donate_app/data/apiClient/auth_service.dart';
import 'package:manna_donate_app/data/apiClient/church_service.dart';
import 'package:manna_donate_app/data/models/user.dart';
import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/data/models/auth_tokens.dart';
import 'package:logger/logger.dart';
import 'package:manna_donate_app/core/navigation_helper.dart';
import 'package:manna_donate_app/core/background_data_fetcher.dart';
import 'package:manna_donate_app/core/cache_manager.dart';
import 'package:manna_donate_app/core/fetch_flags_manager.dart';
import 'dart:io';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ChurchService _churchService = ChurchService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  final CacheManager _cacheManager = CacheManager();

  // Callback for navigation after logout
  VoidCallback? _onLogoutCallback;

  // State variables
  User? _user;
  AuthTokens? _tokens;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _isLoggingOut = false;
  String? _error;
  String? _successMessage;

  // Token refresh state
  bool _isRefreshingToken = false;

  // Getters
  User? get user => _user;
  AuthTokens? get tokens => _tokens;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoggingOut => _isLoggingOut;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get isRefreshingToken => _isRefreshingToken;

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Initialize auth provider
  AuthProvider() {
    // Don't automatically load auth state on construction
    // This will be called manually when the app is ready
    // loadAuthState();
  }

  // Public method to manually load auth state
  // This should be called when the app is ready to check authentication
  Future<void> initializeAuthState() async {
    await loadAuthState();
  }

  // Set logout callback for navigation
  void setLogoutCallback(VoidCallback callback) {
    _onLogoutCallback = callback;
  }

  // Direct logout method that can be called from anywhere
  static void forceLogoutAndNavigate(BuildContext context) {
    try {
      // Navigate to login immediately
      NavigationHelper.forceLogout(context);
    } catch (e) {}
  }

  // Fetch initial data in background after login (legacy method - now handled by BackgroundDataFetcher)
  void fetchInitialDataInBackground() {
    // This method is kept for backward compatibility but is no longer used
    // The comprehensive data fetching is now handled directly in splash and login screens
    _logger.i(
      'Legacy fetchInitialDataInBackground called - use BackgroundDataFetcher.fetchAllDataInBackground() instead',
    );
  }

  void _fetchInitialDataInBackground() {
    fetchInitialDataInBackground();
  }

  // Execute logout navigation with multiple strategies
  void _executeLogoutNavigation() {
    try {
      // Strategy 1: Call the main logout callback immediately
      if (_onLogoutCallback != null) {
        _onLogoutCallback!();
      }
    } catch (e) {
      _logger.e('Strategy 1 failed: $e');

      // Strategy 2: Try with a short delay
      Future.delayed(const Duration(milliseconds: 50), () {
        try {
          if (_onLogoutCallback != null) {
            _onLogoutCallback!();
          }
        } catch (e2) {
          _logger.e('Strategy 2 failed: $e2');

          // Strategy 3: Try with longer delay
          Future.delayed(const Duration(milliseconds: 200), () {
            try {
              if (_onLogoutCallback != null) {
                _onLogoutCallback!();
              }
            } catch (e3) {
              _logger.e('Strategy 3 failed: $e3');

              // Strategy 4: Final attempt with even longer delay
              Future.delayed(const Duration(milliseconds: 500), () {
                try {
                  if (_onLogoutCallback != null) {
                    _onLogoutCallback!();
                  }
                } catch (e4) {
                  _logger.e('All logout navigation strategies failed: $e4');
                }
              });
            }
          });
        }
      });
    }
  }

  // Force navigation to login page (fallback method)
  void _forceNavigateToLogin() {
    try {
      // This is a fallback method that tries to navigate to login
      // It will be called if the main logout callback fails
      if (_onLogoutCallback != null) {
        // Use a delayed callback to ensure the widget tree is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            _onLogoutCallback!();
          } catch (e) {
            _logger.e('Failed to execute logout callback: $e');
            // Try one more time with a longer delay
            Future.delayed(const Duration(milliseconds: 500), () {
              try {
                _onLogoutCallback!();
              } catch (e2) {
                _logger.e('Failed to execute logout callback on retry: $e2');
              }
            });
          }
        });
      }
    } catch (e) {
      _logger.e('Failed to navigate to login page: $e');
    }
  }

  // Check if tokens are expired or about to expire
  bool _areTokensExpired() {
    if (_tokens == null) return true;

    // For now, we'll assume tokens expire after 1 hour
    // In a real app, you'd check the actual expiration time
    // TODO: Implement proper JWT token expiration check
    return false; // Placeholder - implement based on your token structure
  }

  // Validate and refresh tokens if needed
  Future<bool> validateAndRefreshTokens() async {
    try {
      // If we have tokens and user data, we're already authenticated
      if (_tokens != null && _user != null) {
        _setAuthenticated(true);
        return true;
      }

      // If we have tokens but no user data, we need to validate them
      if (_tokens != null) {
        // Always try to fetch user data to validate tokens
        final userFetched = await _fetchUserData();
        if (userFetched && _user != null) {
          _setAuthenticated(true);
          return true;
        }

        // If fetching user data failed, try to refresh tokens
        if (_tokens?.refreshToken != null) {
          _logger.w('User data fetch failed, attempting token refresh');
          final refreshed = await _refreshTokens();
          if (refreshed && _user != null) {
            _setAuthenticated(true);
            return true;
          }
        }
      }

      // Check if tokens are expired (this is currently a placeholder)
      if (_areTokensExpired()) {
        _logger.w('Tokens are expired, attempting refresh');
        if (_tokens?.refreshToken != null) {
          final refreshed = await _refreshTokens();
          if (refreshed && _user != null) {
            _setAuthenticated(true);
            return true;
          }
        }
        await _clearTokens();
        _setAuthenticated(false);
        return false;
      }

      // If all else fails, clear tokens and set as not authenticated
      await _clearTokens();
      _setAuthenticated(false);
      return false;
    } catch (e) {
      _logger.e('Token validation error: $e');
      await _clearTokens();
      _setAuthenticated(false);
      return false;
    }
  }

  // Register new user
  Future<bool> register({
    required String firstName,
    String? lastName,
    String? middleName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        email: email,
        password: password,
        phone: phone,
      );

      if (response.success) {
        // Store registration data for confirmation
        await _storage.write(key: 'pending_registration', value: email);

        _setSuccess(
          'Registration successful. Please check your email for verification.',
        );
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _logger.e('Registration error: $e');
      _setError('Registration failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Confirm registration with access code
  Future<bool> confirmRegistration({
    String? email,
    String? phone,
    required String accessCode,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.verify(
        email ?? '',
        accessCode,
        phone: phone,
      );

      if (response.success) {
        final data = response.data;

        if (data != null) {
          final dataMap = data as Map<String, dynamic>;
          // Parse tokens
          if (dataMap.containsKey('tokens') && dataMap['tokens'] != null) {
            _tokens = AuthTokens.fromJson(dataMap['tokens']);
          }

          // Parse user data
          if (dataMap.containsKey('user') && dataMap['user'] != null) {
            _user = User.fromJson(dataMap['user']);
            notifyListeners(); // Notify listeners that user data has been updated
          }

          // Store tokens securely
          await _storeTokens();

          // Clear pending registration
          await _storage.delete(key: 'pending_registration');

          // Invalidate user-related caches after successful verification
          await _invalidateUserCache();

          // Set authentication state
          _setAuthenticated(true);
          _setSuccess('Account activated successfully');

          _logger.i('User registration confirmed: ${_user?.email}');

          // Fetch all donor data including church data in background after successful registration
          _fetchInitialDataInBackground();

          return true;
        } else {
          _setError('Invalid response data');
          return false;
        }
      } else {
        // Use the specific error message from the backend if available
        final errorMessage = response.errorCode != null
            ? ApiResponse.userFriendlyMessage(
                response.errorCode,
                response.message,
              )
            : response.message;
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      _logger.e('Registration confirmation error: $e');
      _setError('Verification failed. Please check your code.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Resend registration code
  Future<bool> resendRegistrationCode({String? email, String? phone}) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.resendCode(email ?? '', phone: phone);

      if (response.success) {
        final method = phone != null ? 'SMS' : 'email';
        _setSuccess('Verification code sent to your $method');
        return true;
      } else {
        // Use the specific error message from the backend if available
        final errorMessage = response.errorCode != null
            ? ApiResponse.userFriendlyMessage(
                response.errorCode,
                response.message,
              )
            : response.message;
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      _logger.e('Resend code error: $e');
      _setError('Failed to resend verification code');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login user
  Future<bool> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.login(
        email: email,
        phone: phone,
        password: password,
      );

      if (response.success) {
        final data = response.data;

        if (data != null) {
          final dataMap = data as Map<String, dynamic>;
          // Parse tokens
          if (dataMap.containsKey('tokens') && dataMap['tokens'] != null) {
            _tokens = AuthTokens.fromJson(dataMap['tokens']);
          }

          // Parse user data
          if (dataMap.containsKey('user') && dataMap['user'] != null) {
            _user = User.fromJson(dataMap['user']);
          }

          // Store tokens securely
          await _storeTokens();

          // Set authentication state
          _setAuthenticated(true);
          _setSuccess('Login successful');

          _logger.i('User logged in successfully: ${_user?.email}');

          // Fetch all donor data including church data in background after successful login
          _fetchInitialDataInBackground();

          // Force a rebuild to notify listeners
          notifyListeners();

          return true;
        } else {
          _setError('Invalid response data');
          return false;
        }
      } else {
        // Preserve the original error message from the server
        _setError(response.message ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _logger.e('Login error: $e');
      _setError('Login failed. Please check your credentials.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Forgot password
  Future<bool> forgotPassword({String? email, String? phone}) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.forgotPassword(
        email: email,
        phone: phone,
      );

      if (response.success) {
        final method = email != null ? 'email' : 'phone';
        _setSuccess('Password reset instructions sent to your $method');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _logger.e('Forgot password error: $e');
      _setError('Failed to send password reset instructions');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify OTP for forgot password
  Future<bool> verifyOtp({
    String? email,
    String? phone,
    required String accessCode,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.verifyOtp(
        email: email,
        phone: phone,
        accessCode: accessCode,
      );

      if (response.success) {
        _setSuccess('OTP verified successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _logger.e('OTP verification error: $e');
      _setError('OTP verification failed');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword({
    String? email,
    String? phone,
    required String accessCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.resetPassword(
        email: email,
        phone: phone,
        accessCode: accessCode,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response.success) {
        _setSuccess('Password reset successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _logger.e('Reset password error: $e');
      _setError('Failed to reset password');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.changePassword(
        currentPassword,
        newPassword,
      );

      if (response.success) {
        _setSuccess('Password changed successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _logger.e('Change password error: $e');
      _setError('Failed to change password');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify email
  Future<bool> verifyEmail({required String email, required String otp}) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.verifyEmail(email, otp);

      if (response.success) {
        _setSuccess('Email verified successfully');
        await _fetchUserData(); // Refresh user data
        return true;
      } else {
        _setError(response.message ?? 'Failed to verify email');
        return false;
      }
    } catch (e) {
      _logger.e('Email verification error: $e');
      _setError('Failed to verify email');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Resend verification
  Future<bool> resendVerification() async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.resendVerification();

      if (response.success) {
        _setSuccess('Verification code sent successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _logger.e('Resend verification error: $e');
      _setError('Failed to resend verification code');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Google OAuth login
  Future<bool> googleSignIn({required String idToken}) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      // Validate ID token
      if (idToken.isEmpty) {
        _setError('Invalid Google ID token provided');
        return false;
      }

      final response = await _authService.googleSignIn(idToken);

      if (response.success) {
        final data = response.data;

        if (data != null) {
          final dataMap = data as Map<String, dynamic>;

          // Parse tokens
          if (dataMap.containsKey('tokens') && dataMap['tokens'] != null) {
            _tokens = AuthTokens.fromJson(dataMap['tokens']);
          }

          // Parse user data
          if (dataMap.containsKey('user') && dataMap['user'] != null) {
            _user = User.fromJson(dataMap['user']);
            notifyListeners();
          }

          // Store tokens securely
          await _storeTokens();

          // Store OAuth provider information
          await _storeOAuthData('google');

          // Set authentication state
          _setAuthenticated(true);
          _setSuccess('Google sign-in successful');

          _logger.i('User signed in with Google: ${_user?.email}');
          return true;
        } else {
          _setError('Invalid response data from server');
          return false;
        }
      } else {
        _setError(response.message ?? 'Google sign-in failed');
        return false;
      }
    } catch (e) {
      _logger.e('Google sign-in error: $e');
      _setError('Google sign-in failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Apple OAuth login
  Future<bool> appleSignIn({
    required String identityToken,
    required String authorizationCode,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.appleSignIn(
        identityToken,
        authorizationCode,
      );

      if (response.success) {
        final data = response.data;

        if (data != null) {
          final dataMap = data as Map<String, dynamic>;
          // Parse tokens
          if (dataMap.containsKey('tokens') && dataMap['tokens'] != null) {
            _tokens = AuthTokens.fromJson(dataMap['tokens']);
          }

          // Parse user data
          if (dataMap.containsKey('user') && dataMap['user'] != null) {
            _user = User.fromJson(dataMap['user']);
            notifyListeners(); // Notify listeners that user data has been updated
          }

          // Store tokens securely
          await _storeTokens();

          // Store OAuth provider information
          await _storeOAuthData('apple');

          // Set authentication state
          _setAuthenticated(true);
          _setSuccess('Apple sign-in successful');

          _logger.i('User signed in with Apple: ${_user?.email}');
          return true;
        } else {
          _setError('Invalid response data');
          return false;
        }
      } else {
        _setError(response.message ?? 'Apple sign-in failed');
        return false;
      }
    } catch (e) {
      _logger.e('Apple sign-in error: $e');
      _setError('Apple sign-in failed');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh token - coordinated with ApiService
  Future<bool> refreshToken() async {
    if (_isRefreshingToken) {
      // Wait for ongoing refresh to complete
      while (_isRefreshingToken) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isAuthenticated;
    }

    try {
      _isRefreshingToken = true;
      notifyListeners();

      if (_tokens?.refreshToken == null) {
        return false;
      }

      final response = await _authService.refreshToken(_tokens!.refreshToken);

      if (response.success) {
        final data = response.data;
        if (data != null) {
          final dataMap = data;
          // Parse tokens
          if (dataMap.containsKey('tokens') && dataMap['tokens'] != null) {
            _tokens = AuthTokens.fromJson(dataMap['tokens']);
          }

          // Parse user data
          if (dataMap.containsKey('user') && dataMap['user'] != null) {
            _user = User.fromJson(dataMap['user']);
            notifyListeners(); // Notify listeners that user data has been updated
          }
          await _storeTokens();

          return true;
        } else {
          _logger.w('Token refresh failed: invalid data');
          return false;
        }
      } else {
        _setError(response.message ?? 'Token refresh failed');
        return false;
      }
    } catch (e) {
      _logger.e('Token refresh error: $e');
      return false;
    } finally {
      _isRefreshingToken = false;
      notifyListeners();
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      _logger.i('Logging out user: ${_user?.email}');
      _setLoggingOut(true);
      _clearError();
      _clearSuccess();

      // Start API call in background with 2-second timeout (non-blocking)
      final apiCall = _authService
          .logout(_tokens?.accessToken, _tokens?.refreshToken)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              _logger.w('Logout API call timed out after 2 seconds');
              return Future.value(); // Return a completed future
            },
          )
          .catchError((e) {
            _logger.e('Logout API error: $e');
            // API errors are ignored - we continue with local cleanup
          });

      // Clear all tokens and user data immediately (don't wait for API)
      await _clearTokens();
      _user = null;
      _tokens = null;
      _setAuthenticated(false);
      _setLoggingOut(false);

      // Execute all cleanup operations in parallel with 2-second timeout
      try {
        await Future.any([
          Future.wait([
            // Critical operations that must complete
            _clearSavedCredentials(),
            _storage.delete(key: 'pending_registration'),

            // Non-critical operations that can timeout
            _clearCachedData().timeout(
              const Duration(seconds: 1),
              onTimeout: () {
                _logger.w('Cache clearing timed out');
                return Future.value();
              },
            ),

            // OAuth sign-out with timeout
            _signOutFromGoogle().timeout(
              const Duration(seconds: 1),
              onTimeout: () {
                _logger.w('Google sign-out timed out');
                return Future.value();
              },
            ),

            _signOutFromApple().timeout(
              const Duration(seconds: 1),
              onTimeout: () {
                _logger.w('Apple sign-out timed out');
                return Future.value();
              },
            ),

            // Cache invalidation with timeout
            BackgroundDataFetcher.invalidateAllCaches().timeout(
              const Duration(seconds: 1),
              onTimeout: () {
                _logger.w('Cache invalidation timed out');
                return Future.value();
              },
            ),

            // Clear all cache data using CacheManager
            _cacheManager.clearAllCaches().timeout(
              const Duration(seconds: 1),
              onTimeout: () {
                _logger.w('CacheManager clearing timed out');
                return Future.value();
              },
            ),

            // Reset all fetch flags
            _resetAllFetchFlags().timeout(
              const Duration(seconds: 1),
              onTimeout: () {
                _logger.w('Fetch flags reset timed out');
                return Future.value();
              },
            ),
          ]),
          Future.delayed(
            const Duration(seconds: 2),
          ), // 2 second overall timeout
        ]);
      } catch (e) {
        _logger.e('Cleanup operations error: $e');
        // Continue even if cleanup fails
      }

      // Reset all state to default values
      _resetToDefaultState();

      // Wait for API call to complete (with 2-second timeout)
      try {
        await Future.any([
          apiCall,
          Future.delayed(const Duration(seconds: 2)), // 2 second timeout
        ]);
        _logger.i('Logout API call completed successfully');
      } catch (e) {
        _logger.e('Logout API timeout or error: $e');
        // API timeout is expected and handled gracefully
      }

      _logger.i('User logged out successfully - all data cleared');
    } catch (e) {
      _logger.e('Logout error: $e');
      // Even if there's an error, ensure local state is cleared immediately
      await _clearTokens();
      _user = null;
      _tokens = null;
      _setAuthenticated(false);
      _setLoggingOut(false);

      // Execute cleanup operations in parallel with timeout
      try {
        await Future.any([
          Future.wait([
            _clearSavedCredentials(),
            _storage.delete(key: 'pending_registration'),
            _clearCachedData().timeout(
              const Duration(seconds: 1),
              onTimeout: () => Future.value(),
            ),
            _signOutFromGoogle().timeout(
              const Duration(seconds: 1),
              onTimeout: () => Future.value(),
            ),
            _signOutFromApple().timeout(
              const Duration(seconds: 1),
              onTimeout: () => Future.value(),
            ),
            BackgroundDataFetcher.invalidateAllCaches().timeout(
              const Duration(seconds: 1),
              onTimeout: () => Future.value(),
            ),
            _cacheManager.clearAllCaches().timeout(
              const Duration(seconds: 1),
              onTimeout: () => Future.value(),
            ),
          ]),
          Future.delayed(
            const Duration(seconds: 2),
          ), // 2 second overall timeout
        ]);
      } catch (e) {
        _logger.e('Error cleanup error: $e');
      }

      // Reset all state to default values
      _resetToDefaultState();
    } finally {
      // Ensure logging out state is always reset
      _setLoggingOut(false);
    }
  }

  // Clear saved credentials
  Future<void> _clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if remember me is enabled
      final rememberMe = prefs.getBool('rememberMe') ?? false;

      // Clear password always
      await prefs.remove('password');

      // Only clear email if remember me is not checked
      if (!rememberMe) {
        await prefs.remove('email');
      }

      // DON'T clear rememberMe state - it should persist across logout
      // await prefs.remove('rememberMe');

      _logger.i(
        'Saved credentials cleared (rememberMe state and email preserved if checked)',
      );
    } catch (e) {
      _logger.e('Error clearing saved credentials: $e');
    }
  }

  // Public method to clear saved credentials
  Future<void> clearCredentials() async {
    await _clearSavedCredentials();
  }

  // Clear all user data (used for registration and OAuth)
  Future<void> clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all saved credentials and user preferences
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.remove('rememberMe');

      // Clear any other user-related data
      await prefs.remove('firstName');
      await prefs.remove('lastName');
      await prefs.remove('phone');
      await prefs.remove('user_id');
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('pending_registration');

      // Clear any cached data
      await prefs.remove('user_data');
      await prefs.remove('church_data');
      await prefs.remove('bank_data');
      await prefs.remove('donation_preferences');
      await prefs.remove('payment_methods');
      await prefs.remove('bank_accounts');

      // Clear OAuth-specific data
      await prefs.remove('google_id');
      await prefs.remove('apple_id');
      await prefs.remove('oauth_provider');

      // Note: Provider data clearing is now handled by UserDataClearer service
      // This prevents circular dependencies and provides better separation of concerns

      _logger.i('All user data cleared');
    } catch (e) {
      _logger.e('Error clearing all user data: $e');
    }
  }

  /// Clear all provider data to prevent data leakage between users
  Future<void> _clearAllProviderData() async {
    try {
      // Clear cache manager data
      await _cacheManager.clearAllCaches();

      // Clear in-memory data in AuthProvider
      _user = null;
      _tokens = null;
      _isAuthenticated = false;
      _isLoading = false;
      _error = null;
      notifyListeners();

      _logger.i('All provider data cleared');
    } catch (e) {
      _logger.e('Error clearing provider data: $e');
    }
  }

  /// Clear in-memory data in AuthProvider
  void clearInMemoryData() {
    _user = null;
    _tokens = null;
    _isAuthenticated = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Fetch user data from API
  Future<bool> _fetchUserData() async {
    try {
      final response = await _authService.getMe().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.w('User data fetch timed out');
          return ApiResponse(success: false, message: 'Request timed out');
        },
      );

      if (response.success) {
        final responseData = response.data;
        if (responseData != null && responseData is Map<String, dynamic>) {
          // Extract user data from the correct path in the response
          final userData = responseData['user'];
          if (userData != null) {
            try {
              _user = User.fromJson(userData);
              notifyListeners(); // Notify listeners that user data has been updated
              return true;
            } catch (e) {
              _logger.e('Error parsing user data: $e');
              _logger.d('User data received: $userData');
              return false;
            }
          } else {
            _logger.w('Failed to fetch user data: user field is null');
            _logger.d('Response data: $responseData');
            return false;
          }
        } else {
          _logger.w('Failed to fetch user data: invalid response data');
          _logger.d('Response data: $responseData');
          return false;
        }
      } else {
        _logger.w('Failed to fetch user data: ${response.message}');
        return false;
      }
    } catch (e) {
      _logger.e('Error fetching user data: $e');
      return false;
    }
  }

  // Refresh access token using refresh token - internal method
  Future<bool> _refreshTokens() async {
    try {
      if (_tokens?.refreshToken == null) {
        return false;
      }

      final response = await _authService
          .refreshToken(_tokens!.refreshToken)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              _logger.w('Token refresh timed out');
              return ApiResponse(success: false, message: 'Request timed out');
            },
          );

      if (response.success) {
        final data = response.data;
        if (data != null) {
          final dataMap = data;
          // Parse tokens
          if (dataMap.containsKey('tokens') && dataMap['tokens'] != null) {
            _tokens = AuthTokens.fromJson(dataMap['tokens']);
          }

          // Parse user data
          if (dataMap.containsKey('user') && dataMap['user'] != null) {
            _user = User.fromJson(dataMap['user']);
            notifyListeners(); // Notify listeners that user data has been updated
          }
          await _storeTokens();

          return true;
        } else {
          _logger.w('Token refresh failed: invalid data');
          return false;
        }
      } else {
        _setError(response.message ?? 'Token refresh failed');
        return false;
      }
    } catch (e) {
      _logger.e('Error refreshing tokens: $e');
      return false;
    }
  }

  // Store tokens securely
  Future<void> _storeTokens() async {
    if (_tokens != null) {
      await _storage.write(key: 'access_token', value: _tokens!.accessToken);
      await _storage.write(key: 'refresh_token', value: _tokens!.refreshToken);

      // Store user data for API service access
      if (_user != null) {
        await _storage.write(key: 'user', value: jsonEncode(_user!.toJson()));
      }

      // Also update ApiService tokens
      // The original code had this line, but ApiService is no longer used directly.
      // This part of the logic needs to be re-evaluated or removed if not applicable.
      // await _apiService.setTokens(
      //   accessToken: _tokens!.accessToken,
      //   refreshToken: _tokens!.refreshToken,
      // );
    }
  }

  // Clear local data
  Future<void> _clearLocalData() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'pending_registration');
  }

  // Clear tokens securely
  Future<void> _clearTokens() async {
    try {
      // Clear tokens in parallel for better performance
      await Future.wait([
        _storage.delete(key: 'access_token'),
        _storage.delete(key: 'refresh_token'),
        _storage.delete(key: 'user'),
        _storage.delete(key: 'user_profile'),
      ]).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          _logger.w('Token clearing timed out');
          return Future.value();
        },
      );
      _tokens = null;
      _logger.i('Tokens cleared from storage');
    } catch (e) {
      _logger.e('Error clearing tokens: $e');
    }
  }

  // Handle error response
  void _handleErrorResponse(dynamic response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final dataMap = data as Map<String, dynamic>;
      final message =
          dataMap['message'] ?? dataMap['detail'] ?? 'An error occurred';
      _setError(message);
    } else {
      _setError('An error occurred');
    }
  }

  // State setters
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    notifyListeners();
  }

  void _setLoggingOut(bool loggingOut) {
    _isLoggingOut = loggingOut;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setSuccess(String? success) {
    _successMessage = success;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  // Clear success message manually
  void clearSuccess() {
    _clearSuccess();
  }

  // Legacy methods for existing screens
  bool get isLoggedIn => _isAuthenticated;
  bool get loading => _isLoading;
  bool get isDarkMode => false; // Default to light mode, can be enhanced later

  List<String> get userChurchIds {
    return _user?.churchIds.map((id) => id.toString()).toList() ?? [];
  }

  // Get current user profile (cache-first)
  Future<bool> getProfile() async {
    try {
      // Try to load from cache first
      final cachedData = await _cacheManager.smartGetCachedData('user_profile');
      if (cachedData != null) {
        _logger.d('Found cached user data: $cachedData');
        try {
          // Handle both direct user data and nested user data structure
          Map<String, dynamic> userData;
          if (cachedData is Map<String, dynamic> &&
              cachedData.containsKey('user')) {
            // Handle nested structure: {user: {...}}
            userData = cachedData['user'] as Map<String, dynamic>;
          } else {
            // Handle direct user data
            userData = cachedData as Map<String, dynamic>;
          }

          _user = User.fromJson(userData);
          await _storage.write(key: 'user', value: jsonEncode(_user!.toJson()));
          _setSuccess('Profile loaded from cache');
          return true;
        } catch (e) {
          _logger.e('Error parsing cached user data: $e');
          _logger.e('Cached data structure: $cachedData');
          // Clear invalid cache data
          await _cacheManager.invalidateCache('user_profile');
          // Continue to API fetch if cache parsing fails
        }
      }

      // If no cache, fetch from API
      return await _fetchProfileFromAPI();
    } catch (e) {
      _logger.e('Get profile error: $e');
      _setError('Failed to get profile');
      return false;
    }
  }

  // Refresh user profile from server (bypass cache)
  Future<bool> refreshProfile() async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.getProfile();
      if (response.success && response.data != null) {
        final data = response.data!;
        _logger.d('API response data: $data');
        
        // Handle nested response structure
        final userData = data['user'] ?? data;
        if (userData != null) {
          _logger.d('User data from API: $userData');
          try {
            _user = User.fromJson(userData);
            await _storage.write(key: 'user', value: jsonEncode(_user!.toJson()));

            // Cache the fresh profile data
            await _cacheManager.cacheData('user_profile', userData);

            _setSuccess('Profile refreshed successfully');
            notifyListeners();
            return true;
          } catch (e) {
            _logger.e('Error parsing user data: $e');
            _logger.e('User data structure: $userData');
            _setError('Failed to parse user data from response');
            return false;
          }
        } else {
          _logger.e('Invalid response data: $data');
          _setError('Invalid response data');
          return false;
        }
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _logger.e('Profile refresh error: $e');
      _setError('Failed to refresh profile. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fetch profile from API (used when cache is invalid or data changes)
  Future<bool> _fetchProfileFromAPI() async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.getProfile();

      if (response.success) {
        final data = response.data;
        _logger.d('API response data: $data');
        if (data != null && data['user'] != null) {
          _logger.d('User data from API: ${data['user']}');
          try {
            _user = User.fromJson(data['user']);
            await _storage.write(
              key: 'user',
              value: jsonEncode(_user!.toJson()),
            );
            // Cache the fresh data
            await _cacheManager.cacheData('user_profile', data['user']);
            _setSuccess('Profile retrieved successfully');
            return true;
          } catch (e) {
            _logger.e('Error parsing user data: $e');
            _logger.e('User data structure: ${data['user']}');
            _setError('Failed to parse user data from response');
            return false;
          }
        } else {
          _logger.e('Invalid response data: $data');
          _setError('Invalid response data');
          return false;
        }
      } else {
        _setError(response.message ?? 'Failed to get profile');
        return false;
      }
    } catch (e) {
      _logger.e('Get profile error: $e');
      _setError('Failed to get profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Invalidate cache when user data changes
  Future<void> _invalidateUserCache() async {
    await _cacheManager.invalidateMultipleCaches([
      'user_profile',
      'user_preferences',
      'profile_image',
    ]);
  }

  // Update profile
  Future<bool> updateProfile({
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    String? avatar,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.updateProfile(
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: email,
        phone: phone,
        avatar: avatar,
      );

      if (response.success) {
        final data = response.data;

        if (data != null && data['user'] != null) {
          try {
            _user = User.fromJson(data['user']);
            await _storage.write(
              key: 'user',
              value: jsonEncode(_user!.toJson()),
            );
            _setSuccess('Profile updated successfully');
            // Invalidate user cache after successful update
            await _invalidateUserCache();
            // Cache the fresh profile data
            await _cacheManager.cacheData('user_profile', data['user']);
            return true;
          } catch (e) {
            _logger.e('Error parsing user data: $e');
            _setError('Failed to parse user data from response');
            return false;
          }
        } else {
          _setError('Invalid response data');
          return false;
        }
      } else {
        _setError(response.message ?? 'Failed to update profile');
        return false;
      }
    } catch (e) {
      _logger.e('Update profile error: $e');
      _setError('Failed to update profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.uploadProfileImage(imageFile);

      if (response.success) {
        final data = response.data;
        if (data != null && data['user'] != null) {
          try {
            _user = User.fromJson(data['user']);
            await _storage.write(
              key: 'user',
              value: jsonEncode(_user!.toJson()),
            );
            _setSuccess('Profile image uploaded successfully');

            _logger.i(
              'Profile image uploaded successfully. New URL: ${_user?.profilePictureUrl}',
            );

            // Invalidate user cache after successful update
            await _invalidateUserCache();

            // Force notify listeners to rebuild UI
            notifyListeners();

            return true;
          } catch (e) {
            _logger.e('Error parsing user data: $e');
            _setError('Failed to parse user data from response');
            return false;
          }
        } else {
          _setError('Invalid response data');
          return false;
        }
      } else {
        _setError(response.message ?? 'Failed to upload profile image');
        return false;
      }
    } catch (e) {
      _logger.e('Upload profile image error: $e');
      _setError('Failed to upload profile image');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove profile image
  Future<bool> removeProfileImage() async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.removeProfileImage();

      if (response.success) {
        final data = response.data;
        if (data != null && data['user'] != null) {
          try {
            _user = User.fromJson(data['user']);
            await _storage.write(
              key: 'user',
              value: jsonEncode(_user!.toJson()),
            );
            _setSuccess('Profile image removed successfully');

            // Invalidate user cache after successful update
            await _invalidateUserCache();

            // Force notify listeners to rebuild UI
            notifyListeners();

            return true;
          } catch (e) {
            _logger.e('Error parsing user data: $e');
            _setError('Failed to parse user data from response');
            return false;
          }
        } else {
          _setError('Invalid response data');
          return false;
        }
      } else {
        _setError(response.message ?? 'Failed to remove profile image');
        return false;
      }
    } catch (e) {
      _logger.e('Remove profile image error: $e');
      _setError('Failed to remove profile image');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.sendEmailVerification();

      if (response.success) {
        _setSuccess('Email verification code sent successfully');
        return true;
      } else {
        _setError(response.message ?? 'Failed to send email verification');
        return false;
      }
    } catch (e) {
      _logger.e('Send email verification error: $e');
      _setError('Failed to send email verification');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Confirm email verification
  Future<bool> confirmEmailVerification(String code) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      // Get the current user's email
      if (_user?.email == null) {
        _setError('No email found for verification');
        return false;
      }

      final response = await _authService.confirmEmailVerification(
        code,
        _user!.email,
      );

      if (response.success) {
        final data = response.data;
        if (data != null && data['user'] != null) {
          try {
            _user = User.fromJson(data['user']);
            await _storage.write(
              key: 'user',
              value: jsonEncode(_user!.toJson()),
            );

            // Invalidate user cache after successful verification
            await _invalidateUserCache();

            // Cache the fresh profile data
            await _cacheManager.cacheData('user_profile', data['user']);

            _setSuccess('Email verified successfully');
            notifyListeners();
            return true;
          } catch (e) {
            _logger.e('Error parsing user data: $e');
            _setError('Failed to parse user data from response');
            return false;
          }
        } else {
          _setError('Invalid response data');
          return false;
        }
      } else {
        _setError(response.message ?? 'Failed to confirm email verification');
        return false;
      }
    } catch (e) {
      _logger.e('Confirm email verification error: $e');
      _setError('Failed to confirm email verification');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send phone verification
  Future<bool> sendPhoneVerification() async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.sendPhoneVerification();

      if (response.success) {
        _setSuccess('Phone verification code sent successfully');
        return true;
      } else {
        _setError(response.message ?? 'Failed to send phone verification');
        return false;
      }
    } catch (e) {
      _logger.e('Send phone verification error: $e');
      _setError('Failed to send phone verification');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Confirm phone verification
  Future<bool> confirmPhoneVerification(String code) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      // Get the current user's phone number
      if (_user?.phone == null) {
        _setError('No phone number found for verification');
        return false;
      }

      final response = await _authService.confirmPhoneVerification(
        code,
        _user!.phone!,
      );

      if (response.success) {
        final data = response.data;
        if (data != null && data['user'] != null) {
          try {
            _user = User.fromJson(data['user']);
            await _storage.write(
              key: 'user',
              value: jsonEncode(_user!.toJson()),
            );

            // Invalidate user cache after successful verification
            await _invalidateUserCache();

            // Cache the fresh profile data
            await _cacheManager.cacheData('user_profile', data['user']);

            _setSuccess('Phone verified successfully');
            notifyListeners();
            return true;
          } catch (e) {
            _logger.e('Error parsing user data: $e');
            _setError('Failed to parse user data from response');
            return false;
          }
        } else {
          _setError('Invalid response data');
          return false;
        }
      } else {
        _setError(response.message ?? 'Failed to confirm phone verification');
        return false;
      }
    } catch (e) {
      _logger.e('Confirm phone verification error: $e');
      _setError('Failed to confirm phone verification');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.verifyPin(pin);

      if (response.success) {
        _setSuccess('PIN verified successfully');
        return true;
      } else {
        _setError(response.message ?? 'Invalid PIN');
        return false;
      }
    } catch (e) {
      _logger.e('Verify PIN error: $e');
      _setError('Failed to verify PIN');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get terms of service
  Future<ApiResponse<Map<String, dynamic>>> getTermsOfService() async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.getTermsOfService();

      if (response.success) {
        return ApiResponse(
          success: true,
          message: 'Terms of service loaded successfully',
          data: response.data ?? {},
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.message ?? 'Failed to load terms of service',
        );
      }
    } catch (e) {
      _logger.e('Get terms of service error: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to load terms of service',
      );
    } finally {
      _setLoading(false);
    }
  }

  // Get privacy policy
  Future<ApiResponse<Map<String, dynamic>>> getPrivacyPolicy() async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      final response = await _authService.getPrivacyPolicy();

      if (response.success) {
        return ApiResponse(
          success: true,
          message: 'Privacy policy loaded successfully',
          data: response.data ?? {},
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.message ?? 'Failed to load privacy policy',
        );
      }
    } catch (e) {
      _logger.e('Get privacy policy error: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to load privacy policy',
      );
    } finally {
      _setLoading(false);
    }
  }

  // Get current access token (with refresh if needed)
  Future<String?> getAccessToken() async {
    if (_tokens?.accessToken != null) {
      return _tokens!.accessToken;
    }

    // Try to refresh tokens
    if (await _refreshTokens()) {
      return _tokens?.accessToken;
    }

    return null;
  }

  // Handle authentication errors from API calls
  Future<void> handleAuthenticationError() async {
    _logger.w('Handling authentication error from API');

    // Try to refresh tokens first
    if (await _refreshTokens()) {
      return; // Successfully refreshed, user can continue
    }

    // If refresh fails, clear all auth data and trigger logout
    await _clearTokens();
    _user = null;
    _setAuthenticated(false);

    // Call logout callback to redirect to login
    if (_onLogoutCallback != null) {
      _logger.i('Calling logout callback due to authentication error');
      _onLogoutCallback!();
    } else {
      _logger.w('No logout callback set for authentication error');
    }
  }

  // Check if user is authenticated and tokens are valid
  Future<bool> isUserAuthenticated() async {
    if (!_isAuthenticated) {
      return false;
    }

    // Validate tokens
    final isValid = await validateAndRefreshTokens();
    return isValid;
  }

  // Load authentication state from secure storage
  Future<void> loadAuthState() async {
    try {
      _setLoading(true);
      _clearError();

      final accessToken = await _storage.read(key: 'access_token');
      final refreshToken = await _storage.read(key: 'refresh_token');

      if (accessToken != null && refreshToken != null) {
        _tokens = AuthTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        // Validate tokens by fetching user data
        final isValid = await validateAndRefreshTokens();

        if (isValid) {
          _logger.i('User authenticated from stored tokens: ${_user?.email}');
        } else {
          _logger.w('Stored tokens are invalid, cleared');
        }
      } else {
        _setAuthenticated(false);
        _logger.i('No stored tokens found');
      }
    } catch (e) {
      _logger.e('Error loading auth state: $e');
      await _clearTokens();
      _setAuthenticated(false);
      _setError('Failed to load authentication state');
    } finally {
      _setLoading(false);
    }
  }

  // Clear cached data
  Future<void> _clearCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all cached user data in parallel
      await Future.wait([
        prefs.remove('user_data'),
        prefs.remove('user_profile'),
        prefs.remove('church_data'),
        prefs.remove('bank_data'),
        prefs.remove('analytics_data'),
        prefs.remove('donation_history'),
        prefs.remove('settings_data'),
      ]).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          _logger.w('Cache clearing timed out');
          return Future.value();
        },
      );

      _logger.i('Cached data cleared successfully');
    } catch (e) {
      _logger.e('Error clearing cached data: $e');
    }
  }

  // Clear OAuth-specific data
  Future<void> _clearOAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('google_id');
      await prefs.remove('apple_id');
      await prefs.remove('oauth_provider');
      _logger.i('OAuth-specific data cleared');
    } catch (e) {
      _logger.e('Error clearing OAuth data: $e');
    }
  }

  // Sign out from Google Sign-In
  Future<void> _signOutFromGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      // Add timeout to prevent blocking
      await googleSignIn.signOut().timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          _logger.w('Google Sign-In signOut timed out');
          return Future.value();
        },
      );
      _logger.i('Successfully signed out from Google Sign-In');
    } catch (e) {
      _logger.e('Error signing out from Google Sign-In: $e');
    }
  }

  // Sign out from Apple Sign-In
  Future<void> _signOutFromApple() async {
    try {
      // Apple Sign-In doesn't have a signOut method like Google Sign-In
      // We just log that we're clearing Apple Sign-In data
      _logger.i('Apple Sign-In data cleared (no signOut method available)');
    } catch (e) {
      _logger.e('Error clearing Apple Sign-In data: $e');
    }
  }

  // Store OAuth provider information
  Future<void> _storeOAuthData(String provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_id', _user?.googleId ?? '');
      await prefs.setString('apple_id', _user?.appleId ?? '');
      await prefs.setString('oauth_provider', provider);
      _logger.i('OAuth data stored for provider: $provider');
    } catch (e) {
      _logger.e('Error storing OAuth data: $e');
    }
  }

  // Reset all fetch flags
  Future<void> _resetAllFetchFlags() async {
    try {
      // Reset all fetch flags using the dedicated service
      FetchFlagsManager.resetAllFlags();
      _logger.i('All fetch flags reset successfully');
    } catch (e) {
      _logger.e('Error in _resetAllFetchFlags: $e');
    }
  }

  // Reset all state to default values
  void _resetToDefaultState() {
    _user = null;
    _tokens = null;
    _isAuthenticated = false;
    _isLoading = false;
    _isLoggingOut = false;
    _error = null;
    _successMessage = null;
    _isRefreshingToken = false;

    // Notify listeners of state change
    notifyListeners();

    _logger.i('Auth state reset to default values');
  }


}
