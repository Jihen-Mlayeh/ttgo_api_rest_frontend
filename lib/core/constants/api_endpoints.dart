class ApiEndpoints {
  // Base URL (sera changée dynamiquement)
  static String baseUrl = 'http://192.168.1.100';

  // Endpoints
  static String get sensors => '$baseUrl/sensors';
  static String get temperature => '$baseUrl/sensors/temperature';
  static String get light => '$baseUrl/sensors/light';
  static String get status => '$baseUrl/status';
  static String get ledOn => '$baseUrl/led/on';
  static String get ledOff => '$baseUrl/led/off';
  static String get ledToggle => '$baseUrl/led/toggle';
  static String get threshold => '$baseUrl/threshold';
  static String thresholdSet(double temp, int light) =>
      '$baseUrl/threshold/set?temp=$temp&light=$light';
  static String modeSet(String mode) =>
      '$baseUrl/mode/set?mode=$mode';

  // Firebase collection names
  static const sensorsCollection = 'sensors';
  static const historyCollection = 'history';
}