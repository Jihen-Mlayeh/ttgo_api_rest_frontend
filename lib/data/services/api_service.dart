import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import '../../core/constants/api_endpoints.dart';

class ApiService {
  Future<SensorData> getSensorData() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.status));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['sensors'] != null) {
          return SensorData(
            temperature: (data['sensors']['temperature'] ?? 0).toDouble(),
            lightRaw: data['sensors']['light_raw'] ?? 0,
            lightPercent: data['sensors']['light_percent'] ?? 0,
            timestamp: DateTime.now(),
            ledState: data['actuators']?['led'] as bool?, // ✅ NOUVEAU
          );
        }

        throw Exception('Invalid data structure');
      } else {
        throw Exception('Failed to load sensor data: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur API getSensorData: $e');
      throw Exception('Failed to load sensor data: $e');
    }
  }
  // ✅ NOUVEAU : Lire l'état de la LED
  Future<bool> getLedState() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.status));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // L'état LED est dans actuators.led
        if (data['actuators'] != null && data['actuators']['led'] != null) {
          return data['actuators']['led'] as bool;
        }

        return false;
      } else {
        throw Exception('Failed to get LED state: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur API getLedState: $e');
      throw Exception('Failed to get LED state: $e');
    }
  }

  Future<void> setLedState(bool isOn) async {
    final url = isOn ? ApiEndpoints.ledOn : ApiEndpoints.ledOff;
    await http.post(Uri.parse(url));
  }

  Future<void> toggleLed() async {
    await http.post(Uri.parse(ApiEndpoints.ledToggle));
  }

  Future<void> setThreshold(double temp, int light) async {
    await http.post(Uri.parse(ApiEndpoints.thresholdSet(temp, light)));
  }

  Future<void> setMode(String mode) async {
    await http.post(Uri.parse(ApiEndpoints.modeSet(mode)));
  }
}