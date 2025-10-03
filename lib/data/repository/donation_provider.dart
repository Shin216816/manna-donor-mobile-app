import 'package:flutter/material.dart';
import 'package:manna_donate_app/data/models/donation_preferences.dart';
import 'package:manna_donate_app/data/apiClient/donation_service.dart';
import 'package:manna_donate_app/data/models/api_response.dart';

class DonationProvider extends ChangeNotifier {
  final DonationService _donationService = DonationService();

  DonationPreferences? _preferences;
  List<Map<String, dynamic>> _history = [];
  bool _loading = false;
  String? _error;

  DonationPreferences? get preferences => _preferences;
  List<Map<String, dynamic>> get history => _history;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchPreferences() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final response = await _donationService.getPreferences();
    if (response.success && response.data != null) {
      _preferences = response.data!;
    } else {
      _error = ApiResponse.userFriendlyMessage(
        response.errorCode,
        response.message,
      );
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchHistory() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final response = await _donationService.getDonationHistory();
    if (response.success && response.data != null) {
      // Convert DonationHistory objects to Map<String, dynamic>
      _history = response.data!.map((history) => history.toJson()).toList();
    } else {
      _error = response.message;
    }
    _loading = false;
    notifyListeners();
  }

  Future<ApiResponse<Map<String, dynamic>>> makeDonation({
    required double amount,
    required int churchId,
    required String description,
    String? paymentMethodId,
  }) async {
    _error = null;
    notifyListeners();
    final response = await _donationService.charge(
      churchId: churchId.toString(),
      amount: amount,
      paymentMethodId: paymentMethodId ?? '',
      description: description,
    );
    if (!response.success) {
      _error = ApiResponse.userFriendlyMessage(
        response.errorCode,
        response.message,
      );
    }
    notifyListeners();
    return response;
  }

  Future<ApiResponse<Map<String, dynamic>>> calculateRoundups({
    required String startDate,
    required String endDate,
    double? multiplier,
    double? threshold,
  }) async {
    return await _donationService.calculateRoundups();
  }

  void clear() {
    _preferences = null;
    _history = [];
    notifyListeners();
  }
}
