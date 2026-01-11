import 'package:flutter/material.dart';
import 'dart:async';
import '../data/models/sensor_data.dart';
import '../data/services/api_service.dart';
import '../data/services/firebase_service.dart';
import '../data/services/mock_api_service.dart';
class SensorProvider with ChangeNotifier {
  // POUR TEST SANS ESP32 :
  // final MockApiService _apiService = MockApiService();

// POUR VRAI ESP32 :
// final ApiService _apiService = ApiService();
  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();

  SensorData? _currentData;
  bool _isLoading = false;
  String? _error;
  Timer? _timer;
  int _fetchCount = 0;

  SensorData? get currentData => _currentData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Démarrer le polling automatique
  void startPolling({Duration interval = const Duration(seconds: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => fetchSensorData());
    fetchSensorData(); // Premier fetch immédiat
  }

  // Arrêter le polling
  void stopPolling() {
    _timer?.cancel();
  }


  Future<void> fetchSensorData() async {
    try {
      _error = null;
      final data = await _apiService.getSensorData();
      _currentData = data;
      _fetchCount++;

      // ✅ SYNCHRONISER L'ÉTAT LED
      // Note: On ne peut pas accéder directement au provider ici
      // On va stocker l'état dans SensorProvider et le lire depuis les widgets

      // Sauvegarder dans Firebase
      try {
        await _firebaseService.saveSensorData(data);
        await _firebaseService.addToHistory(data);
      } catch (firebaseError) {
        print('❌ Erreur Firebase: $firebaseError');
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}