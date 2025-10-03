import 'package:flutter/material.dart';
import 'package:biometric_storage/biometric_storage.dart';

class SecurityProvider extends ChangeNotifier {
  bool _unlocked = false;
  bool get unlocked => _unlocked;

  Future<bool> checkBiometrics() async {
    final canAuthenticate = await BiometricStorage().canAuthenticate();
    return canAuthenticate == CanAuthenticateResponse.success;
  }

  Future<bool> unlockWithBiometrics() async {
    final store = await BiometricStorage().getStorage('app_unlock');
    final result = await store.read();
    if (result != null) {
      _unlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lock() {
    _unlocked = false;
    notifyListeners();
  }

  void unlockWithPin() {
    _unlocked = true;
    notifyListeners();
  }

  /// Clear all data in SecurityProvider
  void clearAllData() {
    _unlocked = false;
    notifyListeners();
  }
} 