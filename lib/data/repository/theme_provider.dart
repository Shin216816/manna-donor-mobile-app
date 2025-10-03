import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import 'package:manna_donate_app/core/theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  // Theme state
  bool _isDarkMode = false;
  bool _isSystemTheme = true;
  bool _isLoading = false;

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isSystemTheme => _isSystemTheme;
  bool get isLoading => _isLoading;

  // Theme getters
  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  // Initialize theme provider
  ThemeProvider() {
    _loadThemePreference();
  }

  // Load theme preference from secure storage
  Future<void> _loadThemePreference() async {
    try {
      _setLoading(true);

      final themeMode = await _storage.read(key: 'theme_mode');
      final isSystemTheme = await _storage.read(key: 'is_system_theme');

      if (themeMode != null) {
        _isDarkMode = themeMode == 'dark';
      }

      if (isSystemTheme != null) {
        _isSystemTheme = isSystemTheme == 'true';
      }

      // If system theme is enabled, check system brightness
      if (_isSystemTheme) {
        _updateSystemTheme();
      }

      _logger.i(
        'Theme preference loaded: dark=$_isDarkMode, system=$_isSystemTheme',
      );
    } catch (e) {
      _logger.e('Error loading theme preference: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle between light and dark theme
  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      _isSystemTheme = false;

      await _saveThemePreference();
      notifyListeners(); // Only notify once after the change
      _logger.i('Theme toggled to: ${_isDarkMode ? 'dark' : 'light'}');
    } catch (e) {
      _logger.e('Error toggling theme: $e');
    }
  }

  // Set specific theme mode
  Future<void> setThemeMode(bool isDark) async {
    try {
      _isDarkMode = isDark;
      _isSystemTheme = false;

      await _saveThemePreference();
      notifyListeners(); // Only notify once after the change
      _logger.i('Theme set to: ${isDark ? 'dark' : 'light'}');
    } catch (e) {
      _logger.e('Error setting theme mode: $e');
    }
  }

  // Enable system theme
  Future<void> enableSystemTheme() async {
    try {
      _isSystemTheme = true;
      _updateSystemTheme();

      await _saveThemePreference();
      _logger.i('System theme enabled');
    } catch (e) {
      _logger.e('Error enabling system theme: $e');
    }
  }

  // Disable system theme
  Future<void> disableSystemTheme() async {
    try {
      _isSystemTheme = false;

      await _saveThemePreference();
      notifyListeners(); // Only notify once after the change
      _logger.i('System theme disabled');
    } catch (e) {
      _logger.e('Error disabling system theme: $e');
    }
  }

  // Update theme based on system brightness
  void _updateSystemTheme() {
    if (_isSystemTheme) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final newIsDark = brightness == Brightness.dark;

      if (_isDarkMode != newIsDark) {
        _isDarkMode = newIsDark;
        notifyListeners();
        _logger.i('System theme updated: ${newIsDark ? 'dark' : 'light'}');
      }
    }
  }

  // Save theme preference to secure storage
  Future<void> _saveThemePreference() async {
    try {
      await _storage.write(
        key: 'theme_mode',
        value: _isDarkMode ? 'dark' : 'light',
      );
      await _storage.write(
        key: 'is_system_theme',
        value: _isSystemTheme.toString(),
      );
    } catch (e) {
      _logger.e('Error saving theme preference: $e');
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get theme mode string
  String get themeModeString {
    if (_isSystemTheme) {
      return 'System';
    }
    return _isDarkMode ? 'Dark' : 'Light';
  }

  // Get theme mode description
  String get themeModeDescription {
    if (_isSystemTheme) {
      return 'Follows your device\'s theme setting';
    }
    return _isDarkMode ? 'Always use dark theme' : 'Always use light theme';
  }

  // Check if theme is customizable
  bool get isThemeCustomizable => true;

  // Get available theme modes
  List<Map<String, dynamic>> get availableThemeModes => [
    {
      'id': 'system',
      'name': 'System',
      'description': 'Follows your device\'s theme setting',
      'isSelected': _isSystemTheme,
    },
    {
      'id': 'light',
      'name': 'Light',
      'description': 'Always use light theme',
      'isSelected': !_isSystemTheme && !_isDarkMode,
    },
    {
      'id': 'dark',
      'name': 'Dark',
      'description': 'Always use dark theme',
      'isSelected': !_isSystemTheme && _isDarkMode,
    },
  ];

  // Set theme mode by ID
  Future<void> setThemeModeById(String themeId) async {
    switch (themeId) {
      case 'system':
        await enableSystemTheme();
        break;
      case 'light':
        await setThemeMode(false);
        break;
      case 'dark':
        await setThemeMode(true);
        break;
      default:
        _logger.w('Unknown theme ID: $themeId');
    }
  }

  // Reset to default theme
  Future<void> resetToDefault() async {
    try {
      _isDarkMode = false;
      _isSystemTheme = true;

      await _saveThemePreference();
      _updateSystemTheme();

      _logger.i('Theme reset to default');
    } catch (e) {
      _logger.e('Error resetting theme: $e');
    }
  }

  // Get theme statistics
  Map<String, dynamic> get themeStats => {
    'isDarkMode': _isDarkMode,
    'isSystemTheme': _isSystemTheme,
    'currentTheme': _isDarkMode ? 'dark' : 'light',
    'themeMode': themeModeString,
  };

  // Export theme preferences
  Map<String, dynamic> exportPreferences() {
    return {
      'theme_mode': _isDarkMode ? 'dark' : 'light',
      'is_system_theme': _isSystemTheme,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  // Import theme preferences
  Future<void> importPreferences(Map<String, dynamic> preferences) async {
    try {
      final themeMode = preferences['theme_mode'] as String?;
      final isSystemTheme = preferences['is_system_theme'] as bool?;

      if (themeMode != null) {
        _isDarkMode = themeMode == 'dark';
      }

      if (isSystemTheme != null) {
        _isSystemTheme = isSystemTheme;
      }

      if (_isSystemTheme) {
        _updateSystemTheme();
      }

      await _saveThemePreference();
      notifyListeners(); // Only notify once after the change
      _logger.i('Theme preferences imported');
    } catch (e) {
      _logger.e('Error importing theme preferences: $e');
    }
  }
}
