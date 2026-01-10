import 'package:flutter/material.dart';
import 'dart:async';
import '../data/models/sensor_data.dart';
import '../data/services/api_service.dart';

class SensorProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  SensorData? _currentData;
  bool _isLoading = false;
  String? _error;
  Timer? _timer;

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

  // Récupérer les données
  Future<void> fetchSensorData() async {
    try {
      _error = null;
      final data = await _apiService.getSensorData();
      _currentData = data;
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