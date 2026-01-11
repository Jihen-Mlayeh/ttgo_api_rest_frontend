import 'package:flutter/material.dart';
import 'dart:math';

class StatsProvider with ChangeNotifier {
  DateTime _startTime = DateTime.now();

  // Données de mode (mock)
  Map<String, double> _modeData = {
    'MANUEL': 45.0,
    'AUTO-TEMP': 35.0,
    'AUTO-LIGHT': 20.0,
  };

  // Données LED par heure (mock - 7 périodes de 4h)
  List<double> _ledData = [65, 45, 30, 55, 70, 80, 60];

  // Stats
  int _totalModeChanges = 42;
  double _avgLedOnTime = 65.5;

  Map<String, double> get modeData => _modeData;
  List<double> get ledData => _ledData;
  int get totalModeChanges => _totalModeChanges;
  double get avgLedOnTime => _avgLedOnTime;

  Duration get uptime => DateTime.now().difference(_startTime);

  String get uptimeString {
    final duration = uptime;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void refreshStats() {
    // Simuler de nouvelles données
    final random = Random();

    // Garder les totaux à 100%
    final m = 20 + random.nextDouble() * 40;
    final at = 20 + random.nextDouble() * 30;
    final al = 100 - m - at;

    _modeData = {
      'MANUEL': m,
      'AUTO-TEMP': at,
      'AUTO-LIGHT': al,
    };

    _ledData = List.generate(7, (_) => 20 + random.nextDouble() * 60);
    _totalModeChanges = 30 + random.nextInt(30);
    _avgLedOnTime = 50 + random.nextDouble() * 30;

    notifyListeners();
  }
}