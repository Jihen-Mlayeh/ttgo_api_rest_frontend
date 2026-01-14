import 'package:flutter_test/flutter_test.dart';
import 'package:ttgo_iot_app/data/models/sensor_data.dart';


void main() {
  group('SensorData Model Tests', () {
    // =========================================================================
    // TESTS fromJson
    // =========================================================================
    group('fromJson', () {
      test('devrait créer SensorData à partir d\'un JSON complet', () {
        // Arrange
        final json = {
          'temperature': 25.5,
          'light_raw': 2048,
          'light_percent': 50,
          'led': true,
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.temperature, equals(25.5));
        expect(sensorData.lightRaw, equals(2048));
        expect(sensorData.lightPercent, equals(50));
        expect(sensorData.ledState, equals(true));
        expect(sensorData.timestamp, isA<DateTime>());
      });

      test('devrait créer SensorData avec LED éteinte', () {
        // Arrange
        final json = {
          'temperature': 30.0,
          'light_raw': 3500,
          'light_percent': 85,
          'led': false,
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.ledState, equals(false));
        expect(sensorData.temperature, equals(30.0));
      });

      test('devrait gérer ledState null (absent du JSON)', () {
        // Arrange
        final json = {
          'temperature': 22.0,
          'light_raw': 1500,
          'light_percent': 36,
          // Pas de champ 'led'
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.ledState, isNull);
        expect(sensorData.temperature, equals(22.0));
        expect(sensorData.lightRaw, equals(1500));
      });

      test('devrait utiliser 0 comme valeur par défaut si température est null', () {
        // Arrange
        final json = {
          'temperature': null,
          'light_raw': 2000,
          'light_percent': 48,
          'led': true,
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.temperature, equals(0.0));
      });

      test('devrait utiliser 0 comme valeur par défaut si light_raw est null', () {
        // Arrange
        final json = {
          'temperature': 25.0,
          'light_raw': null,
          'light_percent': 50,
          'led': false,
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.lightRaw, equals(0));
      });

      test('devrait utiliser 0 comme valeur par défaut si light_percent est null', () {
        // Arrange
        final json = {
          'temperature': 25.0,
          'light_raw': 2000,
          'light_percent': null,
          'led': true,
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.lightPercent, equals(0));
      });

      test('devrait convertir un entier en double pour la température', () {
        // Arrange
        final json = {
          'temperature': 25, // Entier au lieu de double
          'light_raw': 2000,
          'light_percent': 50,
          'led': true,
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.temperature, isA<double>());
        expect(sensorData.temperature, equals(25.0));
      });

      test('devrait gérer des valeurs extrêmes', () {
        // Arrange
        final json = {
          'temperature': -40.0, // Température très basse
          'light_raw': 4095, // Valeur ADC maximale ESP32
          'light_percent': 100,
          'led': true,
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.temperature, equals(-40.0));
        expect(sensorData.lightRaw, equals(4095));
        expect(sensorData.lightPercent, equals(100));
      });

      test('devrait gérer un JSON vide avec valeurs par défaut', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.temperature, equals(0.0));
        expect(sensorData.lightRaw, equals(0));
        expect(sensorData.lightPercent, equals(0));
        expect(sensorData.ledState, isNull);
      });
    });

    // =========================================================================
    // TESTS toJson
    // =========================================================================
    group('toJson', () {
      test('devrait convertir SensorData en JSON complet', () {
        // Arrange
        final timestamp = DateTime(2024, 1, 14, 10, 30, 0);
        final sensorData = SensorData(
          temperature: 25.5,
          lightRaw: 2048,
          lightPercent: 50,
          timestamp: timestamp,
          ledState: true,
        );

        // Act
        final json = sensorData.toJson();

        // Assert
        expect(json['temperature'], equals(25.5));
        expect(json['light_raw'], equals(2048));
        expect(json['light_percent'], equals(50));
        expect(json['timestamp'], equals(timestamp.millisecondsSinceEpoch));
        expect(json['led'], equals(true));
      });

      test('devrait convertir SensorData avec LED éteinte', () {
        // Arrange
        final sensorData = SensorData(
          temperature: 30.0,
          lightRaw: 3000,
          lightPercent: 73,
          timestamp: DateTime.now(),
          ledState: false,
        );

        // Act
        final json = sensorData.toJson();

        // Assert
        expect(json['led'], equals(false));
      });

      test('devrait gérer ledState null dans toJson', () {
        // Arrange
        final sensorData = SensorData(
          temperature: 22.0,
          lightRaw: 1500,
          lightPercent: 36,
          timestamp: DateTime.now(),
          ledState: null, // Explicitement null
        );

        // Act
        final json = sensorData.toJson();

        // Assert
        expect(json.containsKey('led'), isTrue);
        expect(json['led'], isNull);
      });

      test('devrait conserver la précision des nombres décimaux', () {
        // Arrange
        final sensorData = SensorData(
          temperature: 25.55555,
          lightRaw: 2048,
          lightPercent: 50,
          timestamp: DateTime.now(),
          ledState: true,
        );

        // Act
        final json = sensorData.toJson();

        // Assert
        expect(json['temperature'], equals(25.55555));
      });
    });

    // =========================================================================
    // TESTS toFirestore
    // =========================================================================
    group('toFirestore', () {
      test('devrait convertir SensorData en format Firestore', () {
        // Arrange
        final timestamp = DateTime(2024, 1, 14, 10, 30, 0);
        final sensorData = SensorData(
          temperature: 25.5,
          lightRaw: 2048,
          lightPercent: 50,
          timestamp: timestamp,
          ledState: true,
        );

        // Act
        final firestoreData = sensorData.toFirestore();

        // Assert
        expect(firestoreData['temperature'], equals(25.5));
        expect(firestoreData['lightRaw'], equals(2048));
        expect(firestoreData['lightPercent'], equals(50));
        expect(firestoreData['timestamp'], equals(timestamp));
      });

      test('ne devrait PAS inclure ledState dans toFirestore', () {
        // Arrange
        final sensorData = SensorData(
          temperature: 25.5,
          lightRaw: 2048,
          lightPercent: 50,
          timestamp: DateTime.now(),
          ledState: true,
        );

        // Act
        final firestoreData = sensorData.toFirestore();

        // Assert
        expect(firestoreData.containsKey('led'), isFalse);
        expect(firestoreData.containsKey('ledState'), isFalse);
      });

      test('devrait utiliser le timestamp DateTime (pas milliseconds)', () {
        // Arrange
        final timestamp = DateTime(2024, 1, 14, 10, 30, 0);
        final sensorData = SensorData(
          temperature: 25.5,
          lightRaw: 2048,
          lightPercent: 50,
          timestamp: timestamp,
          ledState: true,
        );

        // Act
        final firestoreData = sensorData.toFirestore();

        // Assert
        expect(firestoreData['timestamp'], isA<DateTime>());
        expect(firestoreData['timestamp'], equals(timestamp));
      });
    });

    // =========================================================================
    // TESTS de création directe
    // =========================================================================
    group('Constructor', () {
      test('devrait créer SensorData avec tous les champs', () {
        // Arrange & Act
        final timestamp = DateTime.now();
        final sensorData = SensorData(
          temperature: 25.5,
          lightRaw: 2048,
          lightPercent: 50,
          timestamp: timestamp,
          ledState: true,
        );

        // Assert
        expect(sensorData.temperature, equals(25.5));
        expect(sensorData.lightRaw, equals(2048));
        expect(sensorData.lightPercent, equals(50));
        expect(sensorData.timestamp, equals(timestamp));
        expect(sensorData.ledState, equals(true));
      });

      test('devrait créer SensorData sans ledState (optionnel)', () {
        // Arrange & Act
        final timestamp = DateTime.now();
        final sensorData = SensorData(
          temperature: 25.5,
          lightRaw: 2048,
          lightPercent: 50,
          timestamp: timestamp,
          // ledState non fourni
        );

        // Assert
        expect(sensorData.ledState, isNull);
      });
    });

    // =========================================================================
    // TESTS de scénarios réels
    // =========================================================================
    group('Real-world scenarios', () {
      test('devrait gérer une lecture typique de l\'ESP32', () {
        // Arrange - JSON typique reçu de l'ESP32
        final json = {
          'temperature': 24.8,
          'light_raw': 1856,
          'light_percent': 45,
          'led': true,
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.temperature, closeTo(24.8, 0.1));
        expect(sensorData.lightPercent, greaterThanOrEqualTo(0));
        expect(sensorData.lightPercent, lessThanOrEqualTo(100));
        expect(sensorData.ledState, isNotNull);
      });

      test('devrait gérer une réponse API status complète', () {
        // Arrange - Réponse complète de /status
        final statusJson = {
          'sensors': {
            'temperature': 26.3,
            'light_raw': 2500,
            'light_percent': 61,
          },
          'actuators': {
            'led': false,
          },
        };

        // Act - Extraire les données capteurs
        final sensorJson = {
          'temperature': statusJson['sensors']?['temperature'],
          'light_raw': statusJson['sensors']?['light_raw'],
          'light_percent': statusJson['sensors']?['light_percent'],
          'led': statusJson['actuators']?['led'],
        };
        final sensorData = SensorData.fromJson(sensorJson);

        // Assert
        expect(sensorData.temperature, equals(26.3));
        expect(sensorData.lightRaw, equals(2500));
        expect(sensorData.lightPercent, equals(61));
        expect(sensorData.ledState, equals(false));
      });

      test('devrait gérer des données en mode AUTO-TEMP', () {
        // Arrange
        final json = {
          'temperature': 35.5, // Au-dessus du seuil
          'light_raw': 2000,
          'light_percent': 48,
          'led': true, // LED allumée automatiquement
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.temperature, greaterThan(30.0));
        expect(sensorData.ledState, isTrue);
      });

      test('devrait gérer des données en mode AUTO-LIGHT', () {
        // Arrange
        final json = {
          'temperature': 25.0,
          'light_raw': 500,
          'light_percent': 12, // Très sombre
          'led': true, // LED allumée automatiquement
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.lightPercent, lessThan(50));
        expect(sensorData.ledState, isTrue);
      });

      test('devrait sérialiser/désérialiser sans perte de données', () {
        // Arrange
        final original = SensorData(
          temperature: 25.5,
          lightRaw: 2048,
          lightPercent: 50,
          timestamp: DateTime(2024, 1, 14, 10, 30, 0),
          ledState: true,
        );

        // Act
        final json = original.toJson();
        final reconstructed = SensorData.fromJson(json);

        // Assert
        expect(reconstructed.temperature, equals(original.temperature));
        expect(reconstructed.lightRaw, equals(original.lightRaw));
        expect(reconstructed.lightPercent, equals(original.lightPercent));
        expect(reconstructed.ledState, equals(original.ledState));
        // Note: timestamp sera différent car fromJson utilise DateTime.now()
      });
    });

    // =========================================================================
    // TESTS de validation des données
    // =========================================================================
    group('Data validation', () {
      test('température devrait être dans une plage réaliste pour NTC 10k', () {
        // Arrange
        final json = {
          'temperature': 25.5,
          'light_raw': 2000,
          'light_percent': 50,
          'led': true,
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.temperature, greaterThanOrEqualTo(-40.0));
        expect(sensorData.temperature, lessThanOrEqualTo(85.0));
      });

      test('light_raw devrait être dans la plage ADC ESP32 (0-4095)', () {
        // Arrange
        final json = {
          'temperature': 25.0,
          'light_raw': 2048,
          'light_percent': 50,
          'led': true,
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.lightRaw, greaterThanOrEqualTo(0));
        expect(sensorData.lightRaw, lessThanOrEqualTo(4095));
      });

      test('light_percent devrait être entre 0 et 100', () {
        // Arrange
        final json = {
          'temperature': 25.0,
          'light_raw': 2048,
          'light_percent': 50,
          'led': true,
        };

        // Act
        final sensorData = SensorData.fromJson(json);

        // Assert
        expect(sensorData.lightPercent, greaterThanOrEqualTo(0));
        expect(sensorData.lightPercent, lessThanOrEqualTo(100));
      });

      test('ledState devrait être un booléen ou null', () {
        // Arrange & Act
        final sensorWithLed = SensorData(
          temperature: 25.0,
          lightRaw: 2000,
          lightPercent: 50,
          timestamp: DateTime.now(),
          ledState: true,
        );

        final sensorWithoutLed = SensorData(
          temperature: 25.0,
          lightRaw: 2000,
          lightPercent: 50,
          timestamp: DateTime.now(),
        );

        // Assert
        expect(sensorWithLed.ledState, isA<bool>());
        expect(sensorWithoutLed.ledState, isNull);
      });
    });
  });
}
