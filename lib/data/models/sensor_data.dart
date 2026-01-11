class SensorData {
  final double temperature;
  final int lightRaw;
  final int lightPercent;
  final DateTime timestamp;
  final bool? ledState; // ✅ NOUVEAU

  SensorData({
    required this.temperature,
    required this.lightRaw,
    required this.lightPercent,
    required this.timestamp,
    this.ledState, // ✅ NOUVEAU (optionnel)
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] ?? 0).toDouble(),
      lightRaw: json['light_raw'] ?? 0,
      lightPercent: json['light_percent'] ?? 0,
      timestamp: DateTime.now(),
      ledState: json['led'], // ✅ NOUVEAU
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'light_raw': lightRaw,
      'light_percent': lightPercent,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'led': ledState, // ✅ NOUVEAU
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'temperature': temperature,
      'lightRaw': lightRaw,
      'lightPercent': lightPercent,
      'timestamp': timestamp,
      // Ne pas sauvegarder ledState dans Firestore (optionnel)
    };
  }
}