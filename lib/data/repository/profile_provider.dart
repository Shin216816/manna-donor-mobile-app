import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:io';

import 'package:manna_donate_app/data/apiClient/profile_service.dart';
import 'package:manna_donate_app/data/models/user.dart';
import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/core/profile_workflow_manager.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final Logger _logger = Logger();

  // State variables
  User? _user;
  Map<String, dynamic>? _profileStats;
  Map<String, dynamic>? _profileActivity;
  Map<String, dynamic>? _preferences;
  Map<String, dynamic>? _securitySettings;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;
  String? _successMessage;

  // Profile update state
  bool _hasPendingChanges = false;
  Map<String, dynamic> _pendingChanges = {};

  // Getters
  User? get user => _user;
  Map<String, dynamic>? get profileStats => _profileStats;
  Map<String, dynamic>? get profileActivity => _profileActivity;
  Map<String, dynamic>? get preferences => _preferences;
  Map<String, dynamic>? get securitySettings => _securitySettings;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get hasPendingChanges => _hasPendingChanges;
  Map<String, dynamic> get pendingChanges => _pendingChanges;

  // Initialize profile provider
  ProfileProvider() {
    _loadProfileData();
  }

  /// Load profile data
  Future<void> _loadProfileData() async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      // Load user profile
      final profileResponse = await _profileService.getProfile();
      if (profileResponse.success && profileResponse.data != null) {
        _user = User.fromJson(profileResponse.data!);
      }

      // Load profile statistics
      final statsResponse = await _profileService.getProfileStats();
      if (statsResponse.success) {
        _profileStats = statsResponse.data;
      }

      // Load preferences
      final preferencesResponse = await _profileService.getPreferences();
      if (preferencesResponse.success) {
        _preferences = preferencesResponse.data;
      }

      // Load security settings
      final securityResponse = await _profileService.getSecuritySettings();
      if (securityResponse.success) {
        _securitySettings = securityResponse.data;
      }

      notifyListeners();
    } catch (e) {
      _logger.e('Error loading profile data: $e');
      _setError('Failed to load profile data');
    } finally {
      _setLoading(false);
    }
  }

  /// Public method to refresh profile data (for cache invalidation)
  Future<void> refreshProfileData() async {
    await _loadProfileData();
  }

  /// Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      _setUpdating(true);
      _clearError();
      _clearSuccess();

      final response = await _profileService.uploadProfileImage(imageFile);

      if (response.success && response.data != null) {
        // Update user profile picture URL
        if (_user != null && response.data!['image_url'] != null) {
          _user = _user!.copyWith(
            profilePictureUrl: response.data!['image_url'],
            updatedAt: DateTime.now(),
          );
        }
        
        // Update user data if provided
        if (response.data!['user'] != null) {
          _user = User.fromJson(response.data!['user']);
        }
        
        _setSuccess('Profile image uploaded successfully');
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to upload profile image');
        return false;
      }
    } catch (e) {
      _logger.e('Upload profile image error: $e');
      _setError('Failed to upload profile image');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Remove profile image
  Future<bool> removeProfileImage() async {
    try {
      _setUpdating(true);
      _clearError();
      _clearSuccess();

      final response = await _profileService.removeProfileImage();

      if (response.success && response.data != null) {
        // Update user profile picture URL
        if (_user != null) {
          _user = _user!.copyWith(
            profilePictureUrl: null,
            updatedAt: DateTime.now(),
          );
        }
        
        // Update user data if provided
        if (response.data!['user'] != null) {
          _user = User.fromJson(response.data!['user']);
        }
        
        _setSuccess('Profile image removed successfully');
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to remove profile image');
        return false;
      }
    } catch (e) {
      _logger.e('Remove profile image error: $e');
      _setError('Failed to remove profile image');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Get profile image info
  Future<Map<String, dynamic>?> getProfileImageInfo() async {
    try {
      final response = await _profileService.getProfileImage();
      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      _logger.e('Get profile image info error: $e');
      return null;
    }
  }

  /// Update profile
  Future<bool> updateProfile({
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
      _setUpdating(true);
      _clearError();
      _clearSuccess();

      final changes = <String, dynamic>{};
      if (firstName != null) changes['firstName'] = firstName;
      if (lastName != null) changes['lastName'] = lastName;
      if (email != null) changes['email'] = email;
      if (phone != null) changes['phone'] = phone;
      if (bio != null) changes['bio'] = bio;
      if (timezone != null) changes['timezone'] = timezone;
      if (language != null) changes['language'] = language;
      if (currency != null) changes['currency'] = currency;

      final success = await ProfileWorkflowManager.startProfileUpdate(
        context: _getContext(),
        changes: changes,
        onProgress: (message) {
          _logger.i('Profile update progress: $message');
        },
        onError: (error) {
          _setError(error);
        },
        onSuccess: () {
          _setSuccess('Profile updated successfully');
          _clearPendingChanges();
        },
      );

      if (success) {
        await _loadProfileData();
      }

      return success;
    } catch (e) {
      _logger.e('Update profile error: $e');
      _setError('Failed to update profile');
      return false;
    } finally {
      _setUpdating(false);
    }
  }





  /// Update preferences
  Future<bool> updatePreferences({
    Map<String, dynamic>? notifications,
    Map<String, dynamic>? privacy,
    Map<String, dynamic>? display,
  }) async {
    try {
      _setUpdating(true);
      _clearError();
      _clearSuccess();

      final response = await _profileService.updatePreferences(
        notifications: notifications,
        privacy: privacy,
        display: display,
      );

      if (response.success) {
        _preferences = response.data;
        _setSuccess('Preferences updated successfully');
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to update preferences');
        return false;
      }
    } catch (e) {
      _logger.e('Update preferences error: $e');
      _setError('Failed to update preferences');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Update security settings
  Future<bool> updateSecuritySettings({
    bool? twoFactorEnabled,
    bool? biometricEnabled,
    String? securityQuestions,
    Map<String, dynamic>? deviceSettings,
  }) async {
    try {
      _setUpdating(true);
      _clearError();
      _clearSuccess();

      final response = await _profileService.updateSecuritySettings(
        twoFactorEnabled: twoFactorEnabled,
        biometricEnabled: biometricEnabled,
        securityQuestions: securityQuestions,
        deviceSettings: deviceSettings,
      );

      if (response.success) {
        _securitySettings = response.data;
        _setSuccess('Security settings updated successfully');
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to update security settings');
        return false;
      }
    } catch (e) {
      _logger.e('Update security settings error: $e');
      _setError('Failed to update security settings');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Get profile activity
  Future<bool> getProfileActivity({
    int? page,
    int? limit,
    String? startDate,
    String? endDate,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _profileService.getProfileActivity(
        page: page,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );

      if (response.success) {
        _profileActivity = response.data;
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to get profile activity');
        return false;
      }
    } catch (e) {
      _logger.e('Get profile activity error: $e');
      _setError('Failed to get profile activity');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Export profile data
  Future<ApiResponse<Map<String, dynamic>>> exportProfileData({
    String? format,
    List<String>? includeFields,
  }) async {
    try {
      _setUpdating(true);
      _clearError();

      final response = await _profileService.exportProfileData(
        format: format,
        includeFields: includeFields,
      );

      if (response.success) {
        _setSuccess('Profile data exported successfully');
      } else {
        _setError(response.message ?? 'Failed to export profile data');
      }

      return response;
    } catch (e) {
      _logger.e('Export profile data error: $e');
      _setError('Failed to export profile data');
      return ApiResponse(
        success: false,
        message: 'Export profile data failed: $e',
      );
    } finally {
      _setUpdating(false);
    }
  }

  /// Request data deletion
  Future<bool> requestDataDeletion({
    String? reason,
    DateTime? scheduledDate,
  }) async {
    try {
      _setUpdating(true);
      _clearError();
      _clearSuccess();

      final response = await _profileService.requestDataDeletion(
        reason: reason,
        scheduledDate: scheduledDate,
      );

      if (response.success) {
        _setSuccess('Data deletion request submitted successfully');
        return true;
      } else {
        _setError(response.message ?? 'Failed to request data deletion');
        return false;
      }
    } catch (e) {
      _logger.e('Request data deletion error: $e');
      _setError('Failed to request data deletion');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Cancel data deletion request
  Future<bool> cancelDataDeletion() async {
    try {
      _setUpdating(true);
      _clearError();
      _clearSuccess();

      final response = await _profileService.cancelDataDeletion();

      if (response.success) {
        _setSuccess('Data deletion request cancelled successfully');
        return true;
      } else {
        _setError(response.message ?? 'Failed to cancel data deletion');
        return false;
      }
    } catch (e) {
      _logger.e('Cancel data deletion error: $e');
      _setError('Failed to cancel data deletion');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Add pending change
  void addPendingChange(String field, dynamic value) {
    _pendingChanges[field] = value;
    _hasPendingChanges = true;
    notifyListeners();
  }

  /// Remove pending change
  void removePendingChange(String field) {
    _pendingChanges.remove(field);
    _hasPendingChanges = _pendingChanges.isNotEmpty;
    notifyListeners();
  }

  /// Clear pending changes
  void _clearPendingChanges() {
    _pendingChanges.clear();
    _hasPendingChanges = false;
    notifyListeners();
  }

  /// Refresh profile data
  Future<void> refreshProfile() async {
    await _loadProfileData();
  }

  /// Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear success message
  void _clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  /// Set success message
  void _setSuccess(String message) {
    _successMessage = message;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set updating state
  void _setUpdating(bool updating) {
    _isUpdating = updating;
    notifyListeners();
  }

  /// Clear all data in ProfileProvider
  void clear() {
    _user = null;
    _profileStats = null;
    _profileActivity = null;
    _preferences = null;
    _securitySettings = null;
    _pendingChanges.clear();
    _hasPendingChanges = false;
    _isLoading = false;
    _isUpdating = false;
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Get context (placeholder - in real implementation, you'd pass context)
  BuildContext _getContext() {
    // This is a placeholder - in a real implementation, you'd handle context properly
    throw UnimplementedError('Context should be passed to methods that need it');
  }
}
