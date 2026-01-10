import 'package:flutter/material.dart';
import '../data/services/api_service.dart';

class LedProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isOn = false;
  bool _isLoading = false;

  bool get isOn => _isOn;
  bool get isLoading => _isLoading;

  Future<void> turnOn() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.setLedState(true);
      _isOn = true;
    } catch (e) {
      // Gérer l'erreur
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> turnOff() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.setLedState(false);
      _isOn = false;
    } catch (e) {
      // Gérer l'erreur
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.toggleLed();
      _isOn = !_isOn;
    } catch (e) {
      // Gérer l'erreur
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setState(bool state) {
    _isOn = state;
    notifyListeners();
  }
}