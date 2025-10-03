import 'package:flutter/material.dart';
import 'package:manna_donate_app/data/apiClient/services.dart';

class ServicesProvider extends ChangeNotifier {
  final MobileService _mobileService = MobileService();

  Map<String, dynamic>? _roundupSettings;
  Map<String, dynamic>? _transactions;
  Map<String, dynamic>? _pendingRoundups;
  Map<String, dynamic>? _donationHistory;
  Map<String, dynamic>? _impactSummary;
  Map<String, dynamic>? _dashboard;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get roundupSettings => _roundupSettings;
  Map<String, dynamic>? get transactions => _transactions;
  Map<String, dynamic>? get pendingRoundups => _pendingRoundups;
  Map<String, dynamic>? get donationHistory => _donationHistory;
  Map<String, dynamic>? get impactSummary => _impactSummary;
  Map<String, dynamic>? get dashboard => _dashboard;
  bool get loading => _loading;
  String? get error => _error;

  /// Fetch roundup settings
  Future<void> fetchRoundupSettings() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final response = await _mobileService.getRoundupSettings();
    if (response.success && response.data != null) {
      _roundupSettings = response.data!;
    } else {
      _error = response.message;
      _roundupSettings = null;
    }
    _loading = false;
    notifyListeners();
  }

  /// Update roundup settings
  Future<void> updateRoundupSettings(Map<String, dynamic> settings) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final response = await _mobileService.updateRoundupSettings(settings);
    if (response.success && response.data != null) {
      _roundupSettings = response.data!;
    } else {
      _error = response.message;
    }
    _loading = false;
    notifyListeners();
  }

  /// Fetch transactions
  Future<void> fetchTransactions({int limit = 20}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final response = await _mobileService.getTransactions(limit: limit);
    if (response.success && response.data != null) {
      _transactions = response.data!;
    } else {
      _error = response.message;
      _transactions = null;
    }
    _loading = false;
    notifyListeners();
  }

  /// Fetch pending roundups
  Future<void> fetchPendingRoundups() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final response = await _mobileService.getPendingRoundups();
    if (response.success && response.data != null) {
      _pendingRoundups = response.data!;
    } else {
      _error = response.message;
      _pendingRoundups = null;
    }
    _loading = false;
    notifyListeners();
  }

  /// Quick toggle roundups (pause/resume)
  Future<void> quickToggleRoundups(bool pause) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final response = await _mobileService.quickToggleRoundups(pause);
    if (response.success && response.data != null) {
      _roundupSettings = response.data!;
    } else {
      _error = response.message;
    }
    _loading = false;
    notifyListeners();
  }

  /// Fetch donation history
  Future<void> fetchDonationHistory({int limit = 20}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final response = await _mobileService.getDonationHistory(limit: limit);
    if (response.success && response.data != null) {
      _donationHistory = response.data!;
    } else {
      _error = response.message;
      _donationHistory = null;
    }
    _loading = false;
    notifyListeners();
  }

  /// Fetch impact summary
  Future<void> fetchImpactSummary() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final response = await _mobileService.getImpactSummary();
    if (response.success && response.data != null) {
      _impactSummary = response.data!;
    } else {
      _error = response.message;
      _impactSummary = null;
    }
    _loading = false;
    notifyListeners();
  }

  /// Fetch dashboard
  Future<void> fetchDashboard() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final response = await _mobileService.getDashboard();
    if (response.success && response.data != null) {
      _dashboard = response.data!;
    } else {
      _error = response.message;
      _dashboard = null;
    }
    _loading = false;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _roundupSettings = null;
    _transactions = null;
    _pendingRoundups = null;
    _donationHistory = null;
    _impactSummary = null;
    _dashboard = null;
    _error = null;
    notifyListeners();
  }
}
