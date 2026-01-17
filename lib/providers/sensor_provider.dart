import 'package:flutter/material.dart';
import 'dart:async';
import '../data/models/sensor_data.dart';
import '../data/services/api_service.dart';
import '../data/services/firebase_service.dart';
import '../data/services/notification_service.dart';

class SensorProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  SensorData? _currentData;
  bool _isLoading = false;
  String? _error;
  Timer? _timer;
  int _fetchCount = 0;

  BuildContext? _context;
  bool? _lastLedState;
  bool _notificationsEnabled = true;

  // 🔧 Variables pour les paramètres
  String _currentMode = 'MANUEL';
  double _tempThreshold = 30.0;
  int _lightThreshold = 50;

  SensorData? get currentData => _currentData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setContext(BuildContext context) {
    print('🔧 setContext appelé');
    _context = context;
  }

  void setNotificationsEnabled(bool enabled) {
    print('🔧 setNotificationsEnabled: $enabled');
    _notificationsEnabled = enabled;
  }

  // ✅ NOUVELLE MÉTHODE pour synchroniser les paramètres
  void updateSettings(String mode, double tempThreshold, int lightThreshold) {
    _currentMode = mode;
    _tempThreshold = tempThreshold;
    _lightThreshold = lightThreshold;
    print('🔧 Paramètres mis à jour: mode=$mode, temp=$tempThreshold, light=$lightThreshold');
  }

  void startPolling({Duration interval = const Duration(seconds: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => fetchSensorData());
    fetchSensorData();
  }

  void stopPolling() {
    _timer?.cancel();
  }

  Future<void> fetchSensorData() async {
    try {
      _error = null;
      final data = await _apiService.getSensorData();
      _currentData = data;
      _fetchCount++;

      print('📊 Données reçues: temp=${data.temperature}°C, light=${data.lightPercent}%, LED=${data.ledState}');

      try {
        await _firebaseService.saveSensorData(data);
        await _firebaseService.addToHistory(data);
      } catch (firebaseError) {
        print('❌ Erreur Firebase: $firebaseError');
      }

      // ✅ VÉRIFICATION AUTOMATIQUE DES NOTIFICATIONS ICI
      _checkNotifications(data);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('❌ Erreur fetchSensorData: $e');
      notifyListeners();
    }
  }

  // ✅ MÉTHODE PRIVÉE qui vérifie automatiquement
  void _checkNotifications(SensorData data) {
    if (_context == null || !_notificationsEnabled || data.ledState == null) {
      return;
    }

    // Initialisation au premier passage
    if (_lastLedState == null) {
      print('ℹ️  Initialisation _lastLedState = ${data.ledState}');
      _lastLedState = data.ledState;
      return;
    }

    // Détection du changement
    if (data.ledState != _lastLedState) {
      print('');
      print('═══════════════════════════════════════════════════');
      print('✅ CHANGEMENT DÉTECTÉ ! ${_lastLedState} → ${data.ledState}');
      print('   Mode: $_currentMode');
      print('   Temp: ${data.temperature}°C (seuil: $_tempThreshold°C)');
      print('   Light: ${data.lightPercent}% (seuil: $_lightThreshold%)');
      print('═══════════════════════════════════════════════════');

      if (data.ledState == true) {
        _showLedOnNotification(data);
      } else {
        _showLedOffNotification(data);
      }

      _lastLedState = data.ledState;
    }
  }

  void _showLedOnNotification(SensorData data) {
    print('📢 Notification LED ON - Mode: $_currentMode');

    switch (_currentMode) {
      case 'AUTO-TEMP':
        if (data.temperature > _tempThreshold) {
          _notificationService.showThresholdNotification(
            _context!,
            '⚠️ Température Élevée',
            'Temp: ${data.temperature.toStringAsFixed(1)}°C > Seuil: ${_tempThreshold.toStringAsFixed(1)}°C\nLED automatiquement allumée',
            Icons.thermostat,
            Colors.red,
          );
        }
        break;

      case 'AUTO-LIGHT':
        if (data.lightPercent < _lightThreshold) {
          _notificationService.showThresholdNotification(
            _context!,
            '💡 Faible Luminosité',
            'Lumière: ${data.lightPercent}% < Seuil: $_lightThreshold%\nLED automatiquement allumée',
            Icons.wb_sunny,
            Colors.orange,
          );
        }
        break;

      case 'MANUEL':
        _notificationService.showThresholdNotification(
          _context!,
          '💡 LED Activée',
          'LED allumée manuellement',
          Icons.touch_app,
          Colors.blue,
        );
        break;
    }
  }

  void _showLedOffNotification(SensorData data) {
    print('📢 Notification LED OFF - Mode: $_currentMode');

    switch (_currentMode) {
      case 'AUTO-TEMP':
        _notificationService.showThresholdNotification(
          _context!,
          '✅ Température Normale',
          'Temp: ${data.temperature.toStringAsFixed(1)}°C ≤ Seuil: ${_tempThreshold.toStringAsFixed(1)}°C\nLED automatiquement éteinte',
          Icons.thermostat,
          Colors.green,
        );
        break;

      case 'AUTO-LIGHT':
        _notificationService.showThresholdNotification(
          _context!,
          '✅ Luminosité Suffisante',
          'Lumière: ${data.lightPercent}% ≥ Seuil: $_lightThreshold%\nLED automatiquement éteinte',
          Icons.wb_sunny,
          Colors.green,
        );
        break;

      case 'MANUEL':
        _notificationService.showThresholdNotification(
          _context!,
          '💡 LED Désactivée',
          'LED éteinte manuellement',
          Icons.touch_app,
          Colors.grey,
        );
        break;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}