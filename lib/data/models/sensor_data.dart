class SensorData {
  final double temperature;
  final int lightRaw;
  final int lightPercent;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.lightRaw,
    required this.lightPercent,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] as num).toDouble(),
      lightRaw: json['light_raw'] as int,
      lightPercent: json['light_percent'] as int,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'light_raw': lightRaw,
      'light_percent': lightPercent,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'temperature': temperature,
      'lightRaw': lightRaw,
      'lightPercent': lightPercent,
      'timestamp': timestamp,
    };
  }
}