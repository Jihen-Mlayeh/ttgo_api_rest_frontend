import 'package:flutter/material.dart';
import '../data/services/api_service.dart';

class LedProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isOn = false;
  bool _isLoading = false;

  bool get isOn => _isOn;
  bool get isLoading => _isLoading;

  // ✅ NOUVEAU : Récupérer l'état depuis l'ESP32
  Future<void> fetchLedState() async {
    try {
      final data = await _apiService.getSensorData();
      // L'API /status retourne l'état LED dans actuators.led
      // On doit parser la réponse pour extraire l'état

      // Pour l'instant, on va ajouter une méthode dans ApiService
      final state = await _apiService.getLedState();
      _isOn = state;
      notifyListeners();
    } catch (e) {
      print('Erreur lecture état LED: $e');
    }
  }

  Future<void> turnOn() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.setLedState(true);
      _isOn = true;
    } catch (e) {
      print('Erreur LED ON: $e');
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
      print('Erreur LED OFF: $e');
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
      print('Erreur LED TOGGLE: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}