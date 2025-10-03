import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:manna_donate_app/data/models/user.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';

class ProfileWorkflowManager {
  static final Logger _logger = Logger();
  
  // Profile update states
  static const String _profileUpdateKey = 'profile_update_in_progress';
  static const String _lastProfileUpdateKey = 'last_profile_update';
  static const String _profileUpdateCountKey = 'profile_update_count';
  
  // Validation states
  static const String _validationErrorsKey = 'profile_validation_errors';
  static const String _pendingChangesKey = 'pending_profile_changes';

  /// Start profile update workflow
  static Future<bool> startProfileUpdate({
    required BuildContext context,
    required Map<String, dynamic> changes,
    required Function(String) onProgress,
    required Function(String) onError,
    required Function() onSuccess,
  }) async {
    try {
      _logger.i('Starting profile update workflow');
      
      // Validate changes
      final validationResult = await _validateProfileChanges(changes);
      if (!validationResult.isValid) {
        onError(validationResult.errorMessage);
        return false;
      }

      // Store pending changes
      await _storePendingChanges(changes);
      
      // Set update in progress
      await _setUpdateInProgress(true);
      
      // Update progress
      onProgress('Validating changes...');

      // Perform the update
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateProfile(
        firstName: changes['firstName'],
        lastName: changes['lastName'],
        phone: changes['phone'],
      );

      if (success) {
        // Clear pending changes
        await _clearPendingChanges();
        
        // Update statistics
        await _updateProfileUpdateStats();
        
        // Refresh user data
        await authProvider.getProfile();
        
        onProgress('Profile updated successfully');
        onSuccess();
        
        _logger.i('Profile update completed successfully');
        return true;
      } else {
        onError('Failed to update profile');
        return false;
      }
    } catch (e) {
      _logger.e('Profile update workflow error: $e');
      onError('Error updating profile: ${e.toString()}');
      return false;
    } finally {
      await _setUpdateInProgress(false);
    }
  }

  /// Start profile image upload workflow
  static Future<bool> startImageUpload({
    required BuildContext context,
    required String imagePath,
    required Function(String) onProgress,
    required Function(String) onError,
    required Function() onSuccess,
  }) async {
    try {
      _logger.i('Starting profile image upload workflow');
      
      // Validate image
      final validationResult = await _validateImage(imagePath);
      if (!validationResult.isValid) {
        onError(validationResult.errorMessage);
        return false;
      }

      onProgress('Uploading image...');

      // Import File here to avoid circular dependency
      final fileClass = await _getFileClass();
      final imageFile = fileClass(imagePath);
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.uploadProfileImage(imageFile);

      if (success) {
        onProgress('Image uploaded successfully');
        onSuccess();
        
        _logger.i('Profile image upload completed successfully');
        return true;
      } else {
        onError('Failed to upload image');
        return false;
      }
    } catch (e) {
      _logger.e('Profile image upload workflow error: $e');
      onError('Error uploading image: ${e.toString()}');
      return false;
    }
  }

  /// Start profile image removal workflow
  static Future<bool> startImageRemoval({
    required BuildContext context,
    required Function(String) onProgress,
    required Function(String) onError,
    required Function() onSuccess,
  }) async {
    try {
      _logger.i('Starting profile image removal workflow');
      
      onProgress('Removing image...');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.removeProfileImage();

      if (success) {
        onProgress('Image removed successfully');
        onSuccess();
        
        _logger.i('Profile image removal completed successfully');
        return true;
      } else {
        onError('Failed to remove image');
        return false;
      }
    } catch (e) {
      _logger.e('Profile image removal workflow error: $e');
      onError('Error removing image: ${e.toString()}');
      return false;
    }
  }

  /// Check if profile update is in progress
  static Future<bool> isProfileUpdateInProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_profileUpdateKey) ?? false;
    } catch (e) {
      _logger.e('Error checking profile update status: $e');
      return false;
    }
  }

  /// Get pending profile changes
  static Future<Map<String, dynamic>?> getPendingChanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final changesJson = prefs.getString(_pendingChangesKey);
      if (changesJson != null) {
        return Map<String, dynamic>.from(
          // Parse JSON here - simplified for now
          {'changes': changesJson}
        );
      }
      return null;
    } catch (e) {
      _logger.e('Error getting pending changes: $e');
      return null;
    }
  }

  /// Get profile update statistics
  static Future<Map<String, dynamic>> getProfileUpdateStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'lastUpdate': prefs.getString(_lastProfileUpdateKey),
        'updateCount': prefs.getInt(_profileUpdateCountKey) ?? 0,
        'isInProgress': prefs.getBool(_profileUpdateKey) ?? false,
      };
    } catch (e) {
      _logger.e('Error getting profile update stats: $e');
      return {};
    }
  }

  /// Validate profile changes
  static Future<ValidationResult> _validateProfileChanges(Map<String, dynamic> changes) async {
    try {
      final errors = <String>[];

      // Validate first name
      if (changes['firstName'] != null) {
        final firstName = changes['firstName'].toString().trim();
        if (firstName.isEmpty) {
          errors.add('First name is required');
        } else if (firstName.length < 2) {
          errors.add('First name must be at least 2 characters');
        } else if (firstName.length > 50) {
          errors.add('First name must be less than 50 characters');
        }
      }

      // Validate last name
      if (changes['lastName'] != null) {
        final lastName = changes['lastName'].toString().trim();
        if (lastName.isNotEmpty && lastName.length < 2) {
          errors.add('Last name must be at least 2 characters');
        } else if (lastName.length > 50) {
          errors.add('Last name must be less than 50 characters');
        }
      }

      // Validate phone number
      if (changes['phone'] != null) {
        final phone = changes['phone'].toString().trim();
        if (phone.isNotEmpty) {
          if (!_isValidPhoneNumber(phone)) {
            errors.add('Please enter a valid phone number');
          }
        }
      }

      // Validate email (if provided)
      if (changes['email'] != null) {
        final email = changes['email'].toString().trim();
        if (email.isNotEmpty && !_isValidEmail(email)) {
          errors.add('Please enter a valid email address');
        }
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        errorMessage: errors.join(', '),
      );
    } catch (e) {
      _logger.e('Error validating profile changes: $e');
      return ValidationResult(
        isValid: false,
        errorMessage: 'Validation error: ${e.toString()}',
      );
    }
  }

  /// Validate image file
  static Future<ValidationResult> _validateImage(String imagePath) async {
    try {
      // Check if file exists
      final fileClass = await _getFileClass();
      final file = fileClass(imagePath);
      
      if (!await file.exists()) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Image file not found',
        );
      }

      // Check file size (max 5MB)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Image file size must be less than 5MB',
        );
      }

      // Check file extension
      final extension = imagePath.split('.').last.toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
      if (!allowedExtensions.contains(extension)) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Only JPG, PNG, and GIF files are allowed',
        );
      }

      return ValidationResult(
        isValid: true,
        errorMessage: '',
      );
    } catch (e) {
      _logger.e('Error validating image: $e');
      return ValidationResult(
        isValid: false,
        errorMessage: 'Image validation error: ${e.toString()}',
      );
    }
  }

  /// Store pending changes
  static Future<void> _storePendingChanges(Map<String, dynamic> changes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // In a real implementation, you'd serialize the changes properly
      await prefs.setString(_pendingChangesKey, changes.toString());
    } catch (e) {
      _logger.e('Error storing pending changes: $e');
    }
  }

  /// Clear pending changes
  static Future<void> _clearPendingChanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingChangesKey);
    } catch (e) {
      _logger.e('Error clearing pending changes: $e');
    }
  }

  /// Set update in progress flag
  static Future<void> _setUpdateInProgress(bool inProgress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_profileUpdateKey, inProgress);
    } catch (e) {
      _logger.e('Error setting update in progress: $e');
    }
  }

  /// Update profile update statistics
  static Future<void> _updateProfileUpdateStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();
      final currentCount = prefs.getInt(_profileUpdateCountKey) ?? 0;
      
      await prefs.setString(_lastProfileUpdateKey, now);
      await prefs.setInt(_profileUpdateCountKey, currentCount + 1);
    } catch (e) {
      _logger.e('Error updating profile update stats: $e');
    }
  }

  /// Get File class dynamically to avoid import issues
  static Future<dynamic> _getFileClass() async {
    // Return the File class from dart:io
    return File;
  }

  /// Validate phone number
  static bool _isValidPhoneNumber(String phone) {
    // Basic phone number validation
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Validate email address
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String errorMessage;

  ValidationResult({
    required this.isValid,
    required this.errorMessage,
  });
}

/// Profile update progress callback
typedef ProfileUpdateProgressCallback = void Function(String message);

/// Profile update error callback
typedef ProfileUpdateErrorCallback = void Function(String error);

/// Profile update success callback
typedef ProfileUpdateSuccessCallback = void Function();
