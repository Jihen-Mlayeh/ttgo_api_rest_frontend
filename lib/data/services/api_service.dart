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

        // Vérifier la structure des données
        if (data['sensors'] != null) {
          return SensorData.fromJson(data['sensors']);
        } else {
          // Structure alternative (si status retourne directement)
          return SensorData(
            temperature: (data['temperature'] ?? 0).toDouble(),
            lightRaw: data['light_raw'] ?? 0,
            lightPercent: data['light_percent'] ?? 0,
            timestamp: DateTime.now(),
          );
        }
      } else {
        throw Exception('Failed to load sensor data: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur API getSensorData: $e');
      throw Exception('Failed to load sensor data: $e');
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