import 'package:flutter/material.dart';
import 'dart:async';
import '../data/services/firebase_service.dart';
import '../data/models/sensor_data.dart';

class StatsProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  DateTime _startTime = DateTime.now();
  Timer? _timer;

  List<Map<String, dynamic>> _modeData = [];
  List<Map<String, dynamic>> _ledData = [];
  int _totalModeChanges = 0;
  double _avgLedOnTime = 0.0;

  List<Map<String, dynamic>> get modeData => _modeData;
  List<Map<String, dynamic>> get ledData => _ledData;
  int get totalModeChanges => _totalModeChanges;
  double get avgLedOnTime => _avgLedOnTime;

  String get uptimeString {
    final duration = DateTime.now().difference(_startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours}h ${minutes}m ${seconds}s';
  }

  StatsProvider() {
    _startTimer();
    _loadStats();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  Future<void> _loadStats() async {
    await _calculateStats();
  }

  Future<void> refreshStats() async {
    await _calculateStats();
  }

  Future<void> _calculateStats() async {
    try {
      final history = await _firebaseService.getHistory24h().first;

      if (history.isEmpty) {
        _setDefaultData();
        notifyListeners();
        return;
      }

      _calculateModeDistribution(history);
      _calculateLedUsage(history);
      _calculateModeChanges(history);
      _calculateAvgLedTime(history);

      notifyListeners();
    } catch (e) {
      print('Erreur calcul stats: $e');
      _setDefaultData();
      notifyListeners();
    }
  }

  void _calculateModeDistribution(List<SensorData> history) {
    final Map<String, int> modeCounts = {};

    for (var data in history) {
      final mode = data.mode ?? 'MANUEL';
      modeCounts[mode] = (modeCounts[mode] ?? 0) + 1;
    }

    final total = history.length;

    _modeData = [
      {
        'mode': 'MANUEL',
        'value': ((modeCounts['MANUEL'] ?? 0) / total * 100).round(),
        'color': Colors.blue,
      },
      {
        'mode': 'AUTO-TEMP',
        'value': ((modeCounts['AUTO-TEMP'] ?? 0) / total * 100).round(),
        'color': Colors.red,
      },
      {
        'mode': 'AUTO-LIGHT',
        'value': ((modeCounts['AUTO-LIGHT'] ?? 0) / total * 100).round(),
        'color': Colors.orange,
      },
    ];
  }

  void _calculateLedUsage(List<SensorData> history) {
    final periods = ['0h', '4h', '8h', '12h', '16h', '20h', '24h'];
    final Map<String, List<bool>> periodData = {
      for (var p in periods) p: []
    };

    for (var data in history) {
      final hour = data.timestamp.hour;
      final periodIndex = (hour ~/ 4).clamp(0, 5);
      final period = periods[periodIndex];
      periodData[period]!.add(data.ledState ?? false);
    }

    _ledData = periods.map((period) {
      final states = periodData[period]!;
      if (states.isEmpty) return {'period': period, 'value': 0};

      final onCount = states.where((s) => s).length;
      final percentage = (onCount / states.length * 100).round();

      return {'period': period, 'value': percentage};
    }).toList();
  }

  void _calculateModeChanges(List<SensorData> history) {
    if (history.length < 2) {
      _totalModeChanges = 0;
      return;
    }

    int changes = 0;
    for (int i = 1; i < history.length; i++) {
      if (history[i].mode != history[i - 1].mode) {
        changes++;
      }
    }

    _totalModeChanges = changes;
  }

  void _calculateAvgLedTime(List<SensorData> history) {
    if (history.isEmpty) {
      _avgLedOnTime = 0.0;
      return;
    }

    final onCount = history.where((d) => d.ledState == true).length;
    _avgLedOnTime = (onCount / history.length * 100);
  }

  void _setDefaultData() {
    _modeData = [
      {'mode': 'MANUEL', 'value': 0, 'color': Colors.blue},
      {'mode': 'AUTO-TEMP', 'value': 0, 'color': Colors.red},
      {'mode': 'AUTO-LIGHT', 'value': 0, 'color': Colors.orange},
    ];

    _ledData = [
      {'period': '0h', 'value': 0},
      {'period': '4h', 'value': 0},
      {'period': '8h', 'value': 0},
      {'period': '12h', 'value': 0},
      {'period': '16h', 'value': 0},
      {'period': '20h', 'value': 0},
      {'period': '24h', 'value': 0},
    ];

    _totalModeChanges = 0;
    _avgLedOnTime = 0.0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}