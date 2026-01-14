import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';

class SettingsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String _currentMode = 'MANUEL';
  double _tempThreshold = 30.0;
  int _lightThreshold = 50;
  int _refreshInterval = 2;
  bool _notificationsEnabled = true;
  bool _firebaseEnabled = true;
  bool _isDarkMode = false;

  String get currentMode => _currentMode;
  double get temperatureThreshold => _tempThreshold;
  int get lightThreshold => _lightThreshold;
  double get tempThreshold => _tempThreshold;
  int get refreshInterval => _refreshInterval;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get firebaseEnabled => _firebaseEnabled;
  bool get isDarkMode => _isDarkMode;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currentMode = prefs.getString('mode') ?? 'MANUEL';
    _tempThreshold = prefs.getDouble('tempThreshold') ?? 30.0;
    _lightThreshold = prefs.getInt('lightThreshold') ?? 50;
    _refreshInterval = prefs.getInt('refreshInterval') ?? 2;
    _notificationsEnabled = prefs.getBool('notifications') ?? true;
    _firebaseEnabled = prefs.getBool('firebase') ?? true;
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    notifyListeners();
  }

  Future<void> setMode(String mode) async {
    try {
      await _apiService.setMode(mode);
      _currentMode = mode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mode', mode);
      notifyListeners();
    } catch (e) {
      print('Erreur setMode: $e');
    }
  }

  void setTempThreshold(double value) {
    _tempThreshold = value;
    notifyListeners();
  }

  void setLightThreshold(int value) {
    _lightThreshold = value;
    notifyListeners();
  }

  Future<void> applyThresholds() async {
    try {
      await _apiService.setThreshold(_tempThreshold, _lightThreshold);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('tempThreshold', _tempThreshold);
      await prefs.setInt('lightThreshold', _lightThreshold);
      notifyListeners();
    } catch (e) {
      print('Erreur applyThresholds: $e');
    }
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> toggleFirebase() async {
    _firebaseEnabled = !_firebaseEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firebase', _firebaseEnabled);
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    notifyListeners();
  }

  Future<void> setRefreshInterval(int interval) async {
    _refreshInterval = interval;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('refreshInterval', interval);
    notifyListeners();
  }
}