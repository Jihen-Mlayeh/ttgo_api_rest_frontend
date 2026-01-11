import '../models/sensor_data.dart';
import 'dart:math';

class MockApiService {
  final Random _random = Random();

  Future<SensorData> getSensorData() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return SensorData(
      temperature: 20 + _random.nextDouble() * 15, // 20-35°C
      lightRaw: 1000 + _random.nextInt(2000), // 1000-3000
      lightPercent: 30 + _random.nextInt(40), // 30-70%
      timestamp: DateTime.now(),
    );
  }

  Future<void> setLedState(bool isOn) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> toggleLed() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> setThreshold(double temp, int light) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> setMode(String mode) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}