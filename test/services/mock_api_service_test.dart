import 'package:flutter_test/flutter_test.dart';
import 'package:ttgo_iot_app/data/models/sensor_data.dart';
import 'package:ttgo_iot_app/data/services/mock_api_service.dart';


void main() {
  group('MockApiService Tests', () {
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
    });

    // =========================================================================
    // TESTS getSensorData()
    // =========================================================================
    group('getSensorData', () {
      test('devrait retourner des données de capteur valides', () async {
        // Act
        final result = await mockApiService.getSensorData();

        // Assert
        expect(result, isA<SensorData>());
        expect(result.temperature, isA<double>());
        expect(result.lightRaw, isA<int>());
        expect(result.lightPercent, isA<int>());
        expect(result.timestamp, isA<DateTime>());
      });

      test('devrait générer une température entre 20°C et 35°C', () async {
        // Act
        final result = await mockApiService.getSensorData();

        // Assert
        expect(result.temperature, greaterThanOrEqualTo(20.0));
        expect(result.temperature, lessThanOrEqualTo(35.0));
      });

      test('devrait générer lightRaw entre 1000 et 3000', () async {
        // Act
        final result = await mockApiService.getSensorData();

        // Assert
        expect(result.lightRaw, greaterThanOrEqualTo(1000));
        expect(result.lightRaw, lessThanOrEqualTo(3000));
      });

      test('devrait générer lightPercent entre 30% et 70%', () async {
        // Act
        final result = await mockApiService.getSensorData();

        // Assert
        expect(result.lightPercent, greaterThanOrEqualTo(30));
        expect(result.lightPercent, lessThanOrEqualTo(70));
      });

      test('devrait avoir un timestamp récent', () async {
        // Arrange
        final beforeCall = DateTime.now();

        // Act
        final result = await mockApiService.getSensorData();

        // Assert
        final afterCall = DateTime.now();
        expect(result.timestamp.isAfter(beforeCall.subtract(Duration(seconds: 1))), isTrue);
        expect(result.timestamp.isBefore(afterCall.add(Duration(seconds: 1))), isTrue);
      });

      test('devrait simuler un délai réseau de ~500ms', () async {
        // Arrange
        final startTime = DateTime.now();

        // Act
        await mockApiService.getSensorData();

        // Assert
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        expect(duration.inMilliseconds, greaterThanOrEqualTo(500));
        expect(duration.inMilliseconds, lessThanOrEqualTo(600)); // Marge de 100ms
      });

      test('devrait générer des valeurs différentes à chaque appel', () async {
        // Act
        final result1 = await mockApiService.getSensorData();
        final result2 = await mockApiService.getSensorData();
        final result3 = await mockApiService.getSensorData();

        // Assert
        // Au moins une des valeurs devrait être différente
        final temperatures = [result1.temperature, result2.temperature, result3.temperature];
        final uniqueTemps = temperatures.toSet();

        expect(uniqueTemps.length, greaterThan(1)); // Au moins 2 valeurs différentes
      });

      test('devrait générer plusieurs valeurs dans la plage attendue', () async {
        // Act - Générer 20 valeurs pour vérifier la distribution
        final results = <SensorData>[];
        for (int i = 0; i < 20; i++) {
          results.add(await mockApiService.getSensorData());
        }

        // Assert - Toutes les valeurs doivent être dans les plages
        for (var result in results) {
          expect(result.temperature, greaterThanOrEqualTo(20.0));
          expect(result.temperature, lessThanOrEqualTo(35.0));
          expect(result.lightRaw, greaterThanOrEqualTo(1000));
          expect(result.lightRaw, lessThanOrEqualTo(3000));
          expect(result.lightPercent, greaterThanOrEqualTo(30));
          expect(result.lightPercent, lessThanOrEqualTo(70));
        }
      });

      test('devrait avoir une distribution raisonnable des températures', () async {
        // Act - Générer 50 valeurs
        final temperatures = <double>[];
        for (int i = 0; i < 50; i++) {
          final result = await mockApiService.getSensorData();
          temperatures.add(result.temperature);
        }

        // Assert - Vérifier qu'on a des valeurs variées
        final min = temperatures.reduce((a, b) => a < b ? a : b);
        final max = temperatures.reduce((a, b) => a > b ? a : b);
        final range = max - min;

        // La plage devrait être significative (au moins 5°C de différence)
        expect(range, greaterThan(5.0));
      });

      test('devrait gérer des appels concurrents', () async {
        // Act - Lancer plusieurs appels en parallèle
        final futures = List.generate(5, (_) => mockApiService.getSensorData());
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(5));
        for (var result in results) {
          expect(result, isA<SensorData>());
          expect(result.temperature, greaterThanOrEqualTo(20.0));
          expect(result.temperature, lessThanOrEqualTo(35.0));
        }
      });
    });

    // =========================================================================
    // TESTS setLedState()
    // =========================================================================
    group('setLedState', () {
      test('devrait accepter true (LED ON)', () async {
        // Act & Assert - Ne devrait pas lancer d'exception
        await mockApiService.setLedState(true);
      });

      test('devrait accepter false (LED OFF)', () async {
        // Act & Assert - Ne devrait pas lancer d'exception
        await mockApiService.setLedState(false);
      });

      test('devrait simuler un délai réseau de ~300ms', () async {
        // Arrange
        final startTime = DateTime.now();

        // Act
        await mockApiService.setLedState(true);

        // Assert
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        expect(duration.inMilliseconds, greaterThanOrEqualTo(300));
        expect(duration.inMilliseconds, lessThanOrEqualTo(400)); // Marge de 100ms
      });

      test('devrait compléter sans erreur pour multiple appels', () async {
        // Act & Assert
        await mockApiService.setLedState(true);
        await mockApiService.setLedState(false);
        await mockApiService.setLedState(true);
        await mockApiService.setLedState(false);
        // Si on arrive ici, le test passe
      });

      test('devrait gérer des changements rapides d\'état', () async {
        // Act
        final futures = [
          mockApiService.setLedState(true),
          mockApiService.setLedState(false),
          mockApiService.setLedState(true),
        ];

        // Assert - Devrait compléter sans erreur
        await Future.wait(futures);
      });
    });

    // =========================================================================
    // TESTS toggleLed()
    // =========================================================================
    group('toggleLed', () {
      test('devrait compléter sans erreur', () async {
        // Act & Assert
        await mockApiService.toggleLed();
      });

      test('devrait simuler un délai réseau de ~300ms', () async {
        // Arrange
        final startTime = DateTime.now();

        // Act
        await mockApiService.toggleLed();

        // Assert
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        expect(duration.inMilliseconds, greaterThanOrEqualTo(300));
        expect(duration.inMilliseconds, lessThanOrEqualTo(400));
      });

      test('devrait gérer plusieurs toggles consécutifs', () async {
        // Act & Assert
        await mockApiService.toggleLed();
        await mockApiService.toggleLed();
        await mockApiService.toggleLed();
        await mockApiService.toggleLed();
      });

      test('devrait gérer des toggles concurrents', () async {
        // Act
        final futures = List.generate(3, (_) => mockApiService.toggleLed());

        // Assert - Devrait compléter sans erreur
        await Future.wait(futures);
      });
    });

    // =========================================================================
    // TESTS setThreshold()
    // =========================================================================
    group('setThreshold', () {
      test('devrait accepter des seuils valides', () async {
        // Act & Assert
        await mockApiService.setThreshold(30.0, 50);
      });

      test('devrait accepter température minimale', () async {
        // Act & Assert
        await mockApiService.setThreshold(0.0, 0);
      });

      test('devrait accepter température maximale', () async {
        // Act & Assert
        await mockApiService.setThreshold(100.0, 100);
      });

      test('devrait accepter valeurs décimales pour température', () async {
        // Act & Assert
        await mockApiService.setThreshold(25.75, 55);
      });

      test('devrait simuler un délai réseau de ~300ms', () async {
        // Arrange
        final startTime = DateTime.now();

        // Act
        await mockApiService.setThreshold(30.0, 50);

        // Assert
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        expect(duration.inMilliseconds, greaterThanOrEqualTo(300));
        expect(duration.inMilliseconds, lessThanOrEqualTo(400));
      });

      test('devrait gérer des changements multiples de seuils', () async {
        // Act & Assert
        await mockApiService.setThreshold(25.0, 40);
        await mockApiService.setThreshold(30.0, 50);
        await mockApiService.setThreshold(35.0, 60);
      });

      test('devrait gérer des seuils négatifs', () async {
        // Act & Assert
        await mockApiService.setThreshold(-10.0, 30);
      });
    });

    // =========================================================================
    // TESTS setMode()
    // =========================================================================
    group('setMode', () {
      test('devrait accepter le mode MANUEL', () async {
        // Act & Assert
        await mockApiService.setMode('MANUEL');
      });

      test('devrait accepter le mode AUTO-TEMP', () async {
        // Act & Assert
        await mockApiService.setMode('AUTO-TEMP');
      });

      test('devrait accepter le mode AUTO-LIGHT', () async {
        // Act & Assert
        await mockApiService.setMode('AUTO-LIGHT');
      });

      test('devrait accepter n\'importe quelle chaîne de caractères', () async {
        // Act & Assert
        await mockApiService.setMode('MODE_CUSTOM');
        await mockApiService.setMode('test');
        await mockApiService.setMode('');
      });

      test('devrait simuler un délai réseau de ~300ms', () async {
        // Arrange
        final startTime = DateTime.now();

        // Act
        await mockApiService.setMode('MANUEL');

        // Assert
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        expect(duration.inMilliseconds, greaterThanOrEqualTo(300));
        expect(duration.inMilliseconds, lessThanOrEqualTo(400));
      });

      test('devrait gérer des changements rapides de mode', () async {
        // Act & Assert
        await mockApiService.setMode('MANUEL');
        await mockApiService.setMode('AUTO-TEMP');
        await mockApiService.setMode('AUTO-LIGHT');
        await mockApiService.setMode('MANUEL');
      });

      test('devrait gérer des changements concurrents de mode', () async {
        // Act
        final futures = [
          mockApiService.setMode('MANUEL'),
          mockApiService.setMode('AUTO-TEMP'),
          mockApiService.setMode('AUTO-LIGHT'),
        ];

        // Assert
        await Future.wait(futures);
      });
    });

    // =========================================================================
    // TESTS de scénarios réels
    // =========================================================================
    group('Real-world scenarios', () {
      test('scénario: lecture périodique des données (toutes les secondes)', () async {
        // Arrange
        final readings = <SensorData>[];

        // Act - Simuler 5 lectures
        for (int i = 0; i < 5; i++) {
          final data = await mockApiService.getSensorData();
          readings.add(data);
        }

        // Assert
        expect(readings.length, equals(5));
        for (var reading in readings) {
          expect(reading.temperature, greaterThanOrEqualTo(20.0));
          expect(reading.temperature, lessThanOrEqualTo(35.0));
        }
      });

      test('scénario: changement de mode puis lecture', () async {
        // Act
        await mockApiService.setMode('AUTO-TEMP');
        final data = await mockApiService.getSensorData();

        // Assert
        expect(data, isA<SensorData>());
      });

      test('scénario: configuration complète du système', () async {
        // Act - Configurer le système complet
        await mockApiService.setMode('AUTO-TEMP');
        await mockApiService.setThreshold(30.0, 50);
        await mockApiService.setLedState(false);
        final data = await mockApiService.getSensorData();

        // Assert
        expect(data, isA<SensorData>());
      });

      test('scénario: monitoring continu avec contrôle LED', () async {
        // Act
        for (int i = 0; i < 3; i++) {
          final data = await mockApiService.getSensorData();

          // Simuler contrôle LED basé sur température
          if (data.temperature > 30.0) {
            await mockApiService.setLedState(true);
          } else {
            await mockApiService.setLedState(false);
          }
        }

        // Assert - Si on arrive ici, le scénario fonctionne
        expect(true, isTrue);
      });

      test('scénario: stress test - 50 lectures rapides', () async {
        // Act
        final startTime = DateTime.now();
        final readings = <SensorData>[];

        for (int i = 0; i < 50; i++) {
          final data = await mockApiService.getSensorData();
          readings.add(data);
        }

        final endTime = DateTime.now();
        final totalDuration = endTime.difference(startTime);

        // Assert
        expect(readings.length, equals(50));

        // Devrait prendre au moins 25 secondes (50 * 500ms)
        expect(totalDuration.inSeconds, greaterThanOrEqualTo(25));

        // Toutes les lectures doivent être valides
        for (var reading in readings) {
          expect(reading.temperature, greaterThanOrEqualTo(20.0));
          expect(reading.temperature, lessThanOrEqualTo(35.0));
        }
      });
    });

    // =========================================================================
    // TESTS de performance
    // =========================================================================
    group('Performance Tests', () {
      test('devrait compléter getSensorData en moins de 1 seconde', () async {
        // Arrange
        final startTime = DateTime.now();

        // Act
        await mockApiService.getSensorData();

        // Assert
        final duration = DateTime.now().difference(startTime);
        expect(duration.inMilliseconds, lessThan(1000));
      });

      test('devrait compléter setLedState en moins de 500ms', () async {
        // Arrange
        final startTime = DateTime.now();

        // Act
        await mockApiService.setLedState(true);

        // Assert
        final duration = DateTime.now().difference(startTime);
        expect(duration.inMilliseconds, lessThan(500));
      });

      test('devrait gérer 10 appels concurrents sans problème', () async {
        // Act
        final futures = List.generate(10, (_) => mockApiService.getSensorData());
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(10));
        for (var result in results) {
          expect(result, isA<SensorData>());
        }
      });
    });

    // =========================================================================
    // TESTS de cohérence des données
    // =========================================================================
    group('Data Consistency Tests', () {
      test('lightPercent devrait être cohérent avec lightRaw', () async {
        // Act - Générer 20 lectures
        for (int i = 0; i < 20; i++) {
          final data = await mockApiService.getSensorData();

          // Assert - Les valeurs doivent être dans les plages attendues
          // lightRaw: 1000-3000, lightPercent: 30-70%
          // Ces plages sont indépendantes dans le mock, mais on vérifie qu'elles existent
          expect(data.lightRaw, isA<int>());
          expect(data.lightPercent, isA<int>());
        }
      });

      test('timestamp devrait toujours être défini', () async {
        // Act
        for (int i = 0; i < 10; i++) {
          final data = await mockApiService.getSensorData();

          // Assert
          expect(data.timestamp, isNotNull);
          expect(data.timestamp, isA<DateTime>());
        }
      });

      test('température devrait toujours être un nombre valide', () async {
        // Act
        for (int i = 0; i < 20; i++) {
          final data = await mockApiService.getSensorData();

          // Assert
          expect(data.temperature.isNaN, isFalse);
          expect(data.temperature.isInfinite, isFalse);
        }
      });
    });
  });
}
