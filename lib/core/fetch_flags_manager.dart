import 'package:logger/logger.dart';

/// Service to manage fetch flags for different screens
/// This ensures that fetch-once behavior can be reset on logout
class FetchFlagsManager {
  static final Logger _logger = Logger();
  
  // Roundup dashboard screen flags
  static bool _churchMessagesFetchedOnce = false;
  static bool _transactionsFetchedOnce = false;
  
  // Home screen flags
  static bool _homeScreenDataFetchedOnce = false;
  
  // Getters for roundup dashboard flags
  static bool get churchMessagesFetchedOnce => _churchMessagesFetchedOnce;
  static bool get transactionsFetchedOnce => _transactionsFetchedOnce;
  
  // Getters for home screen flags
  static bool get homeScreenDataFetchedOnce => _homeScreenDataFetchedOnce;
  
  // Setters for roundup dashboard flags
  static void setChurchMessagesFetchedOnce(bool value) {
    _churchMessagesFetchedOnce = value;
    _logger.d('Church messages fetched flag set to: $value');
  }
  
  static void setTransactionsFetchedOnce(bool value) {
    _transactionsFetchedOnce = value;
    _logger.d('Transactions fetched flag set to: $value');
  }
  
  // Setters for home screen flags
  static void setHomeScreenDataFetchedOnce(bool value) {
    _homeScreenDataFetchedOnce = value;
    _logger.d('Home screen data fetched flag set to: $value');
  }
  
  /// Reset all fetch flags (called on logout)
  static void resetAllFlags() {
    _churchMessagesFetchedOnce = false;
    _transactionsFetchedOnce = false;
    _homeScreenDataFetchedOnce = false;
    _logger.i('All fetch flags reset');
  }
  
  /// Reset only roundup dashboard flags
  static void resetRoundupDashboardFlags() {
    _churchMessagesFetchedOnce = false;
    _transactionsFetchedOnce = false;
    _logger.i('Roundup dashboard fetch flags reset');
  }
  
  /// Reset only home screen flags
  static void resetHomeScreenFlags() {
    _homeScreenDataFetchedOnce = false;
    _logger.i('Home screen fetch flags reset');
  }
}
