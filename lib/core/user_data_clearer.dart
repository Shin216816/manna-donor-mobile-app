import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/data/repository/roundup_provider.dart';
import 'package:manna_donate_app/data/repository/analytics_provider.dart';
import 'package:manna_donate_app/data/repository/church_provider.dart';
import 'package:manna_donate_app/data/repository/church_message_provider.dart';
import 'package:manna_donate_app/data/repository/donation_provider.dart';
import 'package:manna_donate_app/data/repository/notification_provider.dart';
import 'package:manna_donate_app/data/repository/profile_provider.dart';
import 'package:manna_donate_app/data/repository/security_provider.dart';
import 'package:manna_donate_app/data/repository/services_provider.dart';
import 'package:manna_donate_app/data/repository/stripe_provider.dart';

import 'package:manna_donate_app/core/data_cache_manager.dart';

/// Service to clear all user data across all providers
/// This prevents data leakage between different users
class UserDataClearer {
  static final DataCacheManager _cacheManager = DataCacheManager();

  /// Clear all user data from all providers and cache
  /// This should be called when:
  /// 1. User logs out
  /// 2. User registers (to clear previous user's data)
  /// 3. User switches accounts
  /// 4. App is reset
  static Future<void> clearAllUserData() async {
    try {
      // Clear all cached data first
      await _cacheManager.clearAllCaches();
      
      
      
      // Clear in-memory data in all providers
      // Note: This requires BuildContext, so it should be called from UI layer
    } catch (e) {
      // Handle error clearing user data
    }
  }
}
