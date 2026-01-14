import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' hide MockClient;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ttgo_iot_app/core/constants/api_endpoints.dart';
import 'package:ttgo_iot_app/data/models/sensor_data.dart';
import 'package:ttgo_iot_app/data/services/api_service.dart';


// Générer les mocks avec: flutter pub run build_runner build
@GenerateMocks([http.Client])
import 'api_service_test.mocks.dart';

void main() {
  group('ApiService Tests', () {
    late ApiService apiService;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      apiService = ApiService();
      // Si votre ApiService accepte un client en paramètre, utilisez:
      // apiService = ApiService(client: mockClient);
    });

    // =========================================================================
    // TESTS getSensorData()
    // =========================================================================
    group('getSensorData', () {
      test('devrait retourner SensorData en cas de succès', () async {
        // Arrange
        final responseBody = '''
        {
          "code": 200,
          "status": "OK",
          "sensors": {
            "temperature": 25.5,
            "light_raw": 2048,
            "light_percent": 50
          },
          "actuators": {
            "led": true
          }
        }
        ''';

        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await apiService.getSensorData();

        // Assert
        expect(result, isA<SensorData>());
        expect(result.temperature, equals(25.5));
        expect(result.lightRaw, equals(2048));
        expect(result.lightPercent, equals(50));
        expect(result.ledState, equals(true));
        expect(result.timestamp, isA<DateTime>());

        verify(mockClient.get(Uri.parse(ApiEndpoints.status))).called(1);
      });

      test('devrait gérer LED éteinte', () async {
        // Arrange
        final responseBody = '''
        {
          "sensors": {
            "temperature": 22.0,
            "light_raw": 1500,
            "light_percent": 36
          },
          "actuators": {
            "led": false
          }
        }
        ''';

        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await apiService.getSensorData();

        // Assert
        expect(result.ledState, equals(false));
      });

      test('devrait gérer ledState null si actuators est absent', () async {
        // Arrange
        final responseBody = '''
        {
          "sensors": {
            "temperature": 25.0,
            "light_raw": 2000,
            "light_percent": 48
          }
        }
        ''';

        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await apiService.getSensorData();

        // Assert
        expect(result.ledState, isNull);
      });

      test('devrait utiliser 0 comme valeur par défaut pour température null', () async {
        // Arrange
        final responseBody = '''
        {
          "sensors": {
            "temperature": null,
            "light_raw": 2000,
            "light_percent": 50
          },
          "actuators": {
            "led": true
          }
        }
        ''';

        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await apiService.getSensorData();

        // Assert
        expect(result.temperature, equals(0.0));
      });

      test('devrait utiliser 0 comme valeur par défaut pour light_raw null', () async {
        // Arrange
        final responseBody = '''
        {
          "sensors": {
            "temperature": 25.0,
            "light_raw": null,
            "light_percent": 50
          },
          "actuators": {
            "led": false
          }
        }
        ''';

        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await apiService.getSensorData();

        // Assert
        expect(result.lightRaw, equals(0));
      });

      test('devrait lancer une exception si sensors est null', () async {
        // Arrange
        final responseBody = '''
        {
          "code": 200,
          "status": "OK",
          "actuators": {
            "led": true
          }
        }
        ''';

        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act & Assert
        expect(
              () => apiService.getSensorData(),
          throwsA(isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Invalid data structure'),
          )),
        );
      });

      test('devrait lancer une exception si le code de statut est 404', () async {
        // Arrange
        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response('Not Found', 404));

        // Act & Assert
        expect(
              () => apiService.getSensorData(),
          throwsA(isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Failed to load sensor data: 404'),
          )),
        );
      });

      test('devrait lancer une exception si le code de statut est 500', () async {
        // Arrange
        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response('Server Error', 500));

        // Act & Assert
        expect(
              () => apiService.getSensorData(),
          throwsA(isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Failed to load sensor data: 500'),
          )),
        );
      });

      test('devrait gérer les erreurs réseau', () async {
        // Arrange
        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
              () => apiService.getSensorData(),
          throwsA(isA<Exception>()),
        );
      });

      test('devrait gérer un JSON malformé', () async {
        // Arrange
        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response('Invalid JSON{', 200));

        // Act & Assert
        expect(
              () => apiService.getSensorData(),
          throwsA(isA<Exception>()),
        );
      });
    });

    // =========================================================================
    // TESTS getLedState()
    // =========================================================================
    group('getLedState', () {
      test('devrait retourner true quand LED est allumée', () async {
        // Arrange
        final responseBody = '''
        {
          "sensors": {
            "temperature": 25.0,
            "light_raw": 2000,
            "light_percent": 50
          },
          "actuators": {
            "led": true
          }
        }
        ''';

        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await apiService.getLedState();

        // Assert
        expect(result, isTrue);
      });

      test('devrait retourner false quand LED est éteinte', () async {
        // Arrange
        final responseBody = '''
        {
          "sensors": {
            "temperature": 25.0,
            "light_raw": 2000,
            "light_percent": 50
          },
          "actuators": {
            "led": false
          }
        }
        ''';

        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await apiService.getLedState();

        // Assert
        expect(result, isFalse);
      });

      test('devrait retourner false si actuators est null', () async {
        // Arrange
        final responseBody = '''
        {
          "sensors": {
            "temperature": 25.0,
            "light_raw": 2000,
            "light_percent": 50
          }
        }
        ''';

        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await apiService.getLedState();

        // Assert
        expect(result, isFalse);
      });

      test('devrait retourner false si led est null', () async {
        // Arrange
        final responseBody = '''
        {
          "sensors": {
            "temperature": 25.0,
            "light_raw": 2000,
            "light_percent": 50
          },
          "actuators": {}
        }
        ''';

        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await apiService.getLedState();

        // Assert
        expect(result, isFalse);
      });

      test('devrait lancer une exception si le code de statut est 404', () async {
        // Arrange
        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response('Not Found', 404));

        // Act & Assert
        expect(
              () => apiService.getLedState(),
          throwsA(isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Failed to get LED state: 404'),
          )),
        );
      });

      test('devrait gérer les erreurs réseau', () async {
        // Arrange
        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenThrow(Exception('Connection timeout'));

        // Act & Assert
        expect(
              () => apiService.getLedState(),
          throwsA(isA<Exception>()),
        );
      });
    });

    // =========================================================================
    // TESTS setLedState()
    // =========================================================================
    group('setLedState', () {
      test('devrait appeler ledOn quand isOn est true', () async {
        // Arrange
        when(mockClient.post(Uri.parse(ApiEndpoints.ledOn)))
            .thenAnswer((_) async => http.Response('{"code": 200}', 200));

        // Act
        await apiService.setLedState(true);

        // Assert
        verify(mockClient.post(Uri.parse(ApiEndpoints.ledOn))).called(1);
        verifyNever(mockClient.post(Uri.parse(ApiEndpoints.ledOff)));
      });

      test('devrait appeler ledOff quand isOn est false', () async {
        // Arrange
        when(mockClient.post(Uri.parse(ApiEndpoints.ledOff)))
            .thenAnswer((_) async => http.Response('{"code": 200}', 200));

        // Act
        await apiService.setLedState(false);

        // Assert
        verify(mockClient.post(Uri.parse(ApiEndpoints.ledOff))).called(1);
        verifyNever(mockClient.post(Uri.parse(ApiEndpoints.ledOn)));
      });

      test('devrait gérer les erreurs lors de l\'allumage de la LED', () async {
        // Arrange
        when(mockClient.post(Uri.parse(ApiEndpoints.ledOn)))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
              () => apiService.setLedState(true),
          throwsException,
        );
      });
    });

    // =========================================================================
    // TESTS toggleLed()
    // =========================================================================
    group('toggleLed', () {
      test('devrait appeler l\'endpoint toggle', () async {
        // Arrange
        when(mockClient.post(Uri.parse(ApiEndpoints.ledToggle)))
            .thenAnswer((_) async => http.Response('{"code": 200}', 200));

        // Act
        await apiService.toggleLed();

        // Assert
        verify(mockClient.post(Uri.parse(ApiEndpoints.ledToggle))).called(1);
      });

      test('devrait gérer les erreurs réseau', () async {
        // Arrange
        when(mockClient.post(Uri.parse(ApiEndpoints.ledToggle)))
            .thenThrow(Exception('Connection timeout'));

        // Act & Assert
        expect(
              () => apiService.toggleLed(),
          throwsException,
        );
      });
    });

    // =========================================================================
    // TESTS setThreshold()
    // =========================================================================
    group('setThreshold', () {
      test('devrait appeler l\'endpoint avec les bons paramètres', () async {
        // Arrange
        const temp = 30.0;
        const light = 50;
        final expectedUrl = ApiEndpoints.thresholdSet(temp, light);

        when(mockClient.post(Uri.parse(expectedUrl)))
            .thenAnswer((_) async => http.Response('{"code": 200}', 200));

        // Act
        await apiService.setThreshold(temp, light);

        // Assert
        verify(mockClient.post(Uri.parse(expectedUrl))).called(1);
      });

      test('devrait gérer des valeurs décimales pour la température', () async {
        // Arrange
        const temp = 35.75;
        const light = 60;
        final expectedUrl = ApiEndpoints.thresholdSet(temp, light);

        when(mockClient.post(Uri.parse(expectedUrl)))
            .thenAnswer((_) async => http.Response('{"code": 200}', 200));

        // Act
        await apiService.setThreshold(temp, light);

        // Assert
        verify(mockClient.post(Uri.parse(expectedUrl))).called(1);
      });

      test('devrait gérer les valeurs limites', () async {
        // Arrange
        const temp = 0.0;
        const light = 0;
        final expectedUrl = ApiEndpoints.thresholdSet(temp, light);

        when(mockClient.post(Uri.parse(expectedUrl)))
            .thenAnswer((_) async => http.Response('{"code": 200}', 200));

        // Act
        await apiService.setThreshold(temp, light);

        // Assert
        verify(mockClient.post(Uri.parse(expectedUrl))).called(1);
      });

      test('devrait gérer les erreurs réseau', () async {
        // Arrange
        const temp = 30.0;
        const light = 50;
        final expectedUrl = ApiEndpoints.thresholdSet(temp, light);

        when(mockClient.post(Uri.parse(expectedUrl)))
            .thenThrow(Exception('Connection error'));

        // Act & Assert
        expect(
              () => apiService.setThreshold(temp, light),
          throwsException,
        );
      });
    });

    // =========================================================================
    // TESTS setMode()
    // =========================================================================
    group('setMode', () {
      test('devrait définir le mode MANUEL', () async {
        // Arrange
        const mode = 'MANUEL';
        final expectedUrl = ApiEndpoints.modeSet(mode);

        when(mockClient.post(Uri.parse(expectedUrl)))
            .thenAnswer((_) async => http.Response('{"code": 200}', 200));

        // Act
        await apiService.setMode(mode);

        // Assert
        verify(mockClient.post(Uri.parse(expectedUrl))).called(1);
      });

      test('devrait définir le mode AUTO-TEMP', () async {
        // Arrange
        const mode = 'AUTO-TEMP';
        final expectedUrl = ApiEndpoints.modeSet(mode);

        when(mockClient.post(Uri.parse(expectedUrl)))
            .thenAnswer((_) async => http.Response('{"code": 200}', 200));

        // Act
        await apiService.setMode(mode);

        // Assert
        verify(mockClient.post(Uri.parse(expectedUrl))).called(1);
      });

      test('devrait définir le mode AUTO-LIGHT', () async {
        // Arrange
        const mode = 'AUTO-LIGHT';
        final expectedUrl = ApiEndpoints.modeSet(mode);

        when(mockClient.post(Uri.parse(expectedUrl)))
            .thenAnswer((_) async => http.Response('{"code": 200}', 200));

        // Act
        await apiService.setMode(mode);

        // Assert
        verify(mockClient.post(Uri.parse(expectedUrl))).called(1);
      });

      test('devrait gérer les erreurs réseau', () async {
        // Arrange
        const mode = 'MANUEL';
        final expectedUrl = ApiEndpoints.modeSet(mode);

        when(mockClient.post(Uri.parse(expectedUrl)))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
              () => apiService.setMode(mode),
          throwsException,
        );
      });
    });

    // =========================================================================
    // TESTS de scénarios réels
    // =========================================================================
    group('Real-world scenarios', () {
      test('scénario: lecture complète des données en mode AUTO-TEMP', () async {
        // Arrange
        final responseBody = '''
        {
          "code": 200,
          "status": "OK",
          "sensors": {
            "temperature": 35.5,
            "light_raw": 2000,
            "light_percent": 48
          },
          "actuators": {
            "led": true
          },
          "settings": {
            "auto_mode": true,
            "current_mode": "AUTO-TEMP",
            "temp_threshold": 30.0,
            "light_threshold": 50
          }
        }
        ''';

        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await apiService.getSensorData();

        // Assert
        expect(result.temperature, greaterThan(30.0));
        expect(result.ledState, isTrue);
      });

      test('scénario: changement de mode puis vérification', () async {
        // Arrange
        final modeUrl = ApiEndpoints.modeSet('AUTO-TEMP');
        when(mockClient.post(Uri.parse(modeUrl)))
            .thenAnswer((_) async => http.Response('{"code": 200}', 200));

        final statusResponse = '''
        {
          "sensors": {
            "temperature": 25.0,
            "light_raw": 2000,
            "light_percent": 50
          },
          "actuators": {
            "led": false
          }
        }
        ''';

        when(mockClient.get(Uri.parse(ApiEndpoints.status)))
            .thenAnswer((_) async => http.Response(statusResponse, 200));

        // Act
        await apiService.setMode('AUTO-TEMP');
        final result = await apiService.getSensorData();

        // Assert
        verify(mockClient.post(Uri.parse(modeUrl))).called(1);
        expect(result, isA<SensorData>());
      });
    });
  });
}
