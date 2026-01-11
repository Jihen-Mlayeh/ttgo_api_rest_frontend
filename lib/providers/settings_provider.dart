import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';

class SettingsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Mode actuel
  String _currentMode = 'MANUEL';

  // Seuils
  double _tempThreshold = 30.0;
  int _lightThreshold = 50;

  // Configuration
  int _refreshInterval = 2; // secondes
  bool _notificationsEnabled = false;
  bool _firebaseEnabled = true;

  // Theme
  bool _isDarkMode = false;

  // Getters
  String get currentMode => _currentMode;
  double get tempThreshold => _tempThreshold;
  int get lightThreshold => _lightThreshold;
  int get refreshInterval => _refreshInterval;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get firebaseEnabled => _firebaseEnabled;
  bool get isDarkMode => _isDarkMode;

  // Charger les paramètres depuis SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currentMode = prefs.getString('mode') ?? 'MANUEL';
    _tempThreshold = prefs.getDouble('temp_threshold') ?? 30.0;
    _lightThreshold = prefs.getInt('light_threshold') ?? 50;
    _refreshInterval = prefs.getInt('refresh_interval') ?? 2;
    _notificationsEnabled = prefs.getBool('notifications') ?? false;
    _firebaseEnabled = prefs.getBool('firebase') ?? true;
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  // Sauvegarder les paramètres
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mode', _currentMode);
    await prefs.setDouble('temp_threshold', _tempThreshold);
    await prefs.setInt('light_threshold', _lightThreshold);
    await prefs.setInt('refresh_interval', _refreshInterval);
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setBool('firebase', _firebaseEnabled);
    await prefs.setBool('dark_mode', _isDarkMode);
  }

  // Changer le mode
  Future<void> setMode(String mode) async {
    _currentMode = mode;
    notifyListeners();
    await _saveSettings();

    try {
      await _apiService.setMode(mode);
    } catch (e) {
      print('Erreur changement mode: $e');
    }
  }

  // Changer les seuils
  void setTempThreshold(double value) {
    _tempThreshold = value;
    notifyListeners();
  }

  void setLightThreshold(int value) {
    _lightThreshold = value;
    notifyListeners();
  }

  // Appliquer les seuils (envoyer à l'API)
  Future<void> applyThresholds() async {
    await _saveSettings();

    try {
      await _apiService.setThreshold(_tempThreshold, _lightThreshold);
    } catch (e) {
      print('Erreur application seuils: $e');
    }
  }

  // Autres paramètres
  void setRefreshInterval(int seconds) {
    _refreshInterval = seconds;
    notifyListeners();
    _saveSettings();
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
    _saveSettings();
  }

  void toggleFirebase(bool value) {
    _firebaseEnabled = value;
    notifyListeners();
    _saveSettings();
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
    _saveSettings();
  }
}