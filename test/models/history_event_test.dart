import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ttgo_iot_app/data/models/history_event.dart';
//import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
//import 'package:votre_app/models/history_event.dart';

void main() {
  group('EventType Enum Tests', () {
    test('devrait avoir tous les types d\'événements', () {
      // Assert
      expect(EventType.values.length, equals(6));
      expect(EventType.values, contains(EventType.temperature));
      expect(EventType.values, contains(EventType.light));
      expect(EventType.values, contains(EventType.ledOn));
      expect(EventType.values, contains(EventType.ledOff));
      expect(EventType.values, contains(EventType.modeChange));
      expect(EventType.values, contains(EventType.thresholdChange));
    });

    test('devrait convertir EventType en string', () {
      // Assert
      expect(EventType.temperature.name, equals('temperature'));
      expect(EventType.light.name, equals('light'));
      expect(EventType.ledOn.name, equals('ledOn'));
      expect(EventType.ledOff.name, equals('ledOff'));
      expect(EventType.modeChange.name, equals('modeChange'));
      expect(EventType.thresholdChange.name, equals('thresholdChange'));
    });
  });

  group('HistoryEvent Constructor Tests', () {
    test('devrait créer un HistoryEvent complet avec data', () {
      // Arrange & Act
      final timestamp = DateTime(2024, 1, 14, 10, 30, 0);
      final event = HistoryEvent(
        id: 'event_123',
        type: EventType.temperature,
        title: 'Température élevée',
        description: 'La température a dépassé 30°C',
        timestamp: timestamp,
        data: {
          'temperature': 32.5,
          'threshold': 30.0,
        },
      );

      // Assert
      expect(event.id, equals('event_123'));
      expect(event.type, equals(EventType.temperature));
      expect(event.title, equals('Température élevée'));
      expect(event.description, equals('La température a dépassé 30°C'));
      expect(event.timestamp, equals(timestamp));
      expect(event.data, isNotNull);
      expect(event.data!['temperature'], equals(32.5));
    });

    test('devrait créer un HistoryEvent sans data (null)', () {
      // Arrange & Act
      final event = HistoryEvent(
        id: 'event_456',
        type: EventType.ledOn,
        title: 'LED allumée',
        description: 'LED allumée manuellement',
        timestamp: DateTime.now(),
        data: null,
      );

      // Assert
      expect(event.data, isNull);
    });

    test('devrait créer un HistoryEvent sans fournir data (omis)', () {
      // Arrange & Act
      final event = HistoryEvent(
        id: 'event_789',
        type: EventType.ledOff,
        title: 'LED éteinte',
        description: 'LED éteinte automatiquement',
        timestamp: DateTime.now(),
      );

      // Assert
      expect(event.data, isNull);
    });
  });

  group('HistoryEvent.fromFirestore Tests', () {
    test('devrait créer HistoryEvent depuis Firestore avec data', () {
      // Arrange
      final timestamp = Timestamp.fromDate(DateTime(2024, 1, 14, 10, 30, 0));
      final firestoreDoc = {
        'type': 'temperature',
        'title': 'Alerte température',
        'description': 'Température critique détectée',
        'timestamp': timestamp,
        'data': {
          'temperature': 35.5,
          'previous': 30.0,
        },
      };

      // Act
      final event = HistoryEvent.fromFirestore(firestoreDoc, 'doc_123');

      // Assert
      expect(event.id, equals('doc_123'));
      expect(event.type, equals(EventType.temperature));
      expect(event.title, equals('Alerte température'));
      expect(event.description, equals('Température critique détectée'));
      expect(event.timestamp, isA<DateTime>());
      expect(event.data, isNotNull);
      expect(event.data!['temperature'], equals(35.5));
      expect(event.data!['previous'], equals(30.0));
    });

    test('devrait créer HistoryEvent depuis Firestore sans data', () {
      // Arrange
      final timestamp = Timestamp.fromDate(DateTime.now());
      final firestoreDoc = {
        'type': 'ledOn',
        'title': 'LED activée',
        'description': 'Utilisateur a allumé la LED',
        'timestamp': timestamp,
        'data': null,
      };

      // Act
      final event = HistoryEvent.fromFirestore(firestoreDoc, 'doc_456');

      // Assert
      expect(event.id, equals('doc_456'));
      expect(event.type, equals(EventType.ledOn));
      expect(event.data, isNull);
    });

    test('devrait parser tous les types d\'événements', () {
      final timestamp = Timestamp.fromDate(DateTime.now());

      // Temperature
      var doc = {'type': 'temperature', 'title': 'T', 'description': 'D', 'timestamp': timestamp};
      expect(HistoryEvent.fromFirestore(doc, '1').type, equals(EventType.temperature));

      // Light
      doc = {'type': 'light', 'title': 'T', 'description': 'D', 'timestamp': timestamp};
      expect(HistoryEvent.fromFirestore(doc, '2').type, equals(EventType.light));

      // LED On
      doc = {'type': 'ledOn', 'title': 'T', 'description': 'D', 'timestamp': timestamp};
      expect(HistoryEvent.fromFirestore(doc, '3').type, equals(EventType.ledOn));

      // LED Off
      doc = {'type': 'ledOff', 'title': 'T', 'description': 'D', 'timestamp': timestamp};
      expect(HistoryEvent.fromFirestore(doc, '4').type, equals(EventType.ledOff));

      // Mode Change
      doc = {'type': 'modeChange', 'title': 'T', 'description': 'D', 'timestamp': timestamp};
      expect(HistoryEvent.fromFirestore(doc, '5').type, equals(EventType.modeChange));

      // Threshold Change
      doc = {'type': 'thresholdChange', 'title': 'T', 'description': 'D', 'timestamp': timestamp};
      expect(HistoryEvent.fromFirestore(doc, '6').type, equals(EventType.thresholdChange));
    });

    test('devrait gérer un type inconnu et retourner temperature par défaut', () {
      // Arrange
      final timestamp = Timestamp.fromDate(DateTime.now());
      final firestoreDoc = {
        'type': 'unknown_type',
        'title': 'Test',
        'description': 'Description',
        'timestamp': timestamp,
      };

      // Act
      final event = HistoryEvent.fromFirestore(firestoreDoc, 'doc_unknown');

      // Assert
      expect(event.type, equals(EventType.temperature)); // Valeur par défaut
    });

    test('devrait gérer des données complexes', () {
      // Arrange
      final timestamp = Timestamp.fromDate(DateTime.now());
      final firestoreDoc = {
        'type': 'modeChange',
        'title': 'Changement de mode',
        'description': 'Mode modifié',
        'timestamp': timestamp,
        'data': {
          'previousMode': 'MANUEL',
          'newMode': 'AUTO-TEMP',
          'threshold': 30.0,
          'user': 'admin',
          'metadata': {
            'app_version': '1.0.0',
            'device': 'ESP32',
          },
        },
      };

      // Act
      final event = HistoryEvent.fromFirestore(firestoreDoc, 'doc_complex');

      // Assert
      expect(event.data!['previousMode'], equals('MANUEL'));
      expect(event.data!['newMode'], equals('AUTO-TEMP'));
      expect(event.data!['metadata'], isA<Map>());
      expect(event.data!['metadata']['app_version'], equals('1.0.0'));
    });
  });

  group('HistoryEvent.toFirestore Tests', () {
    test('devrait convertir HistoryEvent en Firestore avec data', () {
      // Arrange
      final timestamp = DateTime(2024, 1, 14, 10, 30, 0);
      final event = HistoryEvent(
        id: 'event_123',
        type: EventType.temperature,
        title: 'Alerte',
        description: 'Température élevée',
        timestamp: timestamp,
        data: {
          'temperature': 35.0,
          'threshold': 30.0,
        },
      );

      // Act
      final firestoreData = event.toFirestore();

      // Assert
      expect(firestoreData['type'], equals('temperature'));
      expect(firestoreData['title'], equals('Alerte'));
      expect(firestoreData['description'], equals('Température élevée'));
      expect(firestoreData['timestamp'], equals(timestamp));
      expect(firestoreData['data'], isNotNull);
      expect(firestoreData['data']['temperature'], equals(35.0));
    });

    test('devrait convertir HistoryEvent en Firestore sans data', () {
      // Arrange
      final event = HistoryEvent(
        id: 'event_456',
        type: EventType.ledOn,
        title: 'LED ON',
        description: 'LED allumée',
        timestamp: DateTime.now(),
        data: null,
      );

      // Act
      final firestoreData = event.toFirestore();

      // Assert
      expect(firestoreData['data'], isNull);
    });

    test('devrait convertir tous les types d\'événements correctement', () {
      final timestamp = DateTime.now();

      // Temperature
      var event = HistoryEvent(id: '1', type: EventType.temperature, title: 'T', description: 'D', timestamp: timestamp);
      expect(event.toFirestore()['type'], equals('temperature'));

      // Light
      event = HistoryEvent(id: '2', type: EventType.light, title: 'T', description: 'D', timestamp: timestamp);
      expect(event.toFirestore()['type'], equals('light'));

      // LED On
      event = HistoryEvent(id: '3', type: EventType.ledOn, title: 'T', description: 'D', timestamp: timestamp);
      expect(event.toFirestore()['type'], equals('ledOn'));

      // LED Off
      event = HistoryEvent(id: '4', type: EventType.ledOff, title: 'T', description: 'D', timestamp: timestamp);
      expect(event.toFirestore()['type'], equals('ledOff'));

      // Mode Change
      event = HistoryEvent(id: '5', type: EventType.modeChange, title: 'T', description: 'D', timestamp: timestamp);
      expect(event.toFirestore()['type'], equals('modeChange'));

      // Threshold Change
      event = HistoryEvent(id: '6', type: EventType.thresholdChange, title: 'T', description: 'D', timestamp: timestamp);
      expect(event.toFirestore()['type'], equals('thresholdChange'));
    });

    test('ne devrait PAS inclure l\'ID dans toFirestore', () {
      // Arrange
      final event = HistoryEvent(
        id: 'event_123',
        type: EventType.temperature,
        title: 'Test',
        description: 'Test event',
        timestamp: DateTime.now(),
      );

      // Act
      final firestoreData = event.toFirestore();

      // Assert
      expect(firestoreData.containsKey('id'), isFalse);
    });
  });

  group('HistoryEvent Round-trip Tests', () {
    test('devrait sérialiser et désérialiser sans perte de données', () {
      // Arrange
      final originalTimestamp = DateTime(2024, 1, 14, 10, 30, 0);
      final original = HistoryEvent(
        id: 'event_original',
        type: EventType.modeChange,
        title: 'Mode changé',
        description: 'Passage en AUTO-TEMP',
        timestamp: originalTimestamp,
        data: {
          'previousMode': 'MANUEL',
          'newMode': 'AUTO-TEMP',
          'threshold': 30.0,
        },
      );

      // Act
      final firestoreData = original.toFirestore();
      // Simuler Firestore Timestamp
      firestoreData['timestamp'] = Timestamp.fromDate(originalTimestamp);
      final reconstructed = HistoryEvent.fromFirestore(firestoreData, 'event_original');

      // Assert
      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.type, equals(original.type));
      expect(reconstructed.title, equals(original.title));
      expect(reconstructed.description, equals(original.description));
      expect(reconstructed.timestamp, equals(original.timestamp));
      expect(reconstructed.data!['previousMode'], equals(original.data!['previousMode']));
      expect(reconstructed.data!['newMode'], equals(original.data!['newMode']));
      expect(reconstructed.data!['threshold'], equals(original.data!['threshold']));
    });
  });

  group('Real-world Scenarios', () {
    test('scénario: événement température élevée en AUTO-TEMP', () {
      // Arrange
      final timestamp = Timestamp.fromDate(DateTime(2024, 1, 14, 15, 30, 0));
      final firestoreDoc = {
        'type': 'temperature',
        'title': 'Alerte température',
        'description': 'La température a dépassé le seuil en mode AUTO-TEMP',
        'timestamp': timestamp,
        'data': {
          'temperature': 35.5,
          'threshold': 30.0,
          'mode': 'AUTO-TEMP',
          'ledActivated': true,
        },
      };

      // Act
      final event = HistoryEvent.fromFirestore(firestoreDoc, 'temp_alert_1');

      // Assert
      expect(event.type, equals(EventType.temperature));
      expect(event.data!['temperature'], greaterThan(event.data!['threshold']));
      expect(event.data!['ledActivated'], isTrue);
    });

    test('scénario: événement lumière faible en AUTO-LIGHT', () {
      // Arrange
      final timestamp = Timestamp.fromDate(DateTime.now());
      final firestoreDoc = {
        'type': 'light',
        'title': 'Lumière faible',
        'description': 'Luminosité sous le seuil',
        'timestamp': timestamp,
        'data': {
          'lightPercent': 25,
          'threshold': 50,
          'mode': 'AUTO-LIGHT',
          'ledActivated': true,
        },
      };

      // Act
      final event = HistoryEvent.fromFirestore(firestoreDoc, 'light_event_1');

      // Assert
      expect(event.type, equals(EventType.light));
      expect(event.data!['lightPercent'], lessThan(event.data!['threshold']));
    });

    test('scénario: changement de mode MANUEL → AUTO-TEMP', () {
      // Arrange
      final event = HistoryEvent(
        id: 'mode_change_1',
        type: EventType.modeChange,
        title: 'Mode AUTO-TEMP activé',
        description: 'Utilisateur a activé le mode automatique température',
        timestamp: DateTime.now(),
        data: {
          'previousMode': 'MANUEL',
          'newMode': 'AUTO-TEMP',
          'tempThreshold': 30.0,
          'lightThreshold': 50,
        },
      );

      // Act
      final firestoreData = event.toFirestore();

      // Assert
      expect(firestoreData['type'], equals('modeChange'));
      expect(firestoreData['data']['previousMode'], equals('MANUEL'));
      expect(firestoreData['data']['newMode'], equals('AUTO-TEMP'));
    });

    test('scénario: LED allumée manuellement', () {
      // Arrange
      final event = HistoryEvent(
        id: 'led_on_1',
        type: EventType.ledOn,
        title: 'LED allumée',
        description: 'LED activée par l\'utilisateur',
        timestamp: DateTime.now(),
        data: {
          'manual': true,
          'source': 'user_app',
        },
      );

      // Act
      final firestoreData = event.toFirestore();

      // Assert
      expect(firestoreData['type'], equals('ledOn'));
      expect(firestoreData['data']['manual'], isTrue);
    });

    test('scénario: modification des seuils', () {
      // Arrange
      final event = HistoryEvent(
        id: 'threshold_change_1',
        type: EventType.thresholdChange,
        title: 'Seuils modifiés',
        description: 'Les seuils de température et lumière ont été mis à jour',
        timestamp: DateTime.now(),
        data: {
          'previousTempThreshold': 30.0,
          'newTempThreshold': 35.0,
          'previousLightThreshold': 50,
          'newLightThreshold': 60,
        },
      );

      // Act
      final firestoreData = event.toFirestore();

      // Assert
      expect(firestoreData['type'], equals('thresholdChange'));
      expect(firestoreData['data']['newTempThreshold'], equals(35.0));
      expect(firestoreData['data']['newLightThreshold'], equals(60));
    });

    test('scénario: historique avec timestamp précis', () {
      // Arrange
      final exactTime = DateTime(2024, 1, 14, 10, 30, 45, 123);
      final event = HistoryEvent(
        id: 'precise_event',
        type: EventType.temperature,
        title: 'Mesure précise',
        description: 'Mesure de température avec timestamp exact',
        timestamp: exactTime,
        data: {'temperature': 25.5},
      );

      // Act
      final firestoreData = event.toFirestore();

      // Assert
      expect(firestoreData['timestamp'], equals(exactTime));
      expect(firestoreData['timestamp'].hour, equals(10));
      expect(firestoreData['timestamp'].minute, equals(30));
      expect(firestoreData['timestamp'].second, equals(45));
    });
  });

  group('Edge Cases and Error Handling', () {
    test('devrait gérer des descriptions très longues', () {
      // Arrange
      final longDescription = 'A' * 1000;
      final event = HistoryEvent(
        id: 'long_desc',
        type: EventType.temperature,
        title: 'Test',
        description: longDescription,
        timestamp: DateTime.now(),
      );

      // Act
      final firestoreData = event.toFirestore();

      // Assert
      expect(firestoreData['description'], equals(longDescription));
      expect(firestoreData['description'].length, equals(1000));
    });

    test('devrait gérer des caractères spéciaux dans le titre', () {
      // Arrange
      final event = HistoryEvent(
        id: 'special_chars',
        type: EventType.ledOn,
        title: 'LED ✓ allumée! 🔥',
        description: 'Test avec émojis et caractères spéciaux: @#\$%^&*()',
        timestamp: DateTime.now(),
      );

      // Act
      final firestoreData = event.toFirestore();

      // Assert
      expect(firestoreData['title'], contains('✓'));
      expect(firestoreData['title'], contains('🔥'));
      expect(firestoreData['description'], contains("@#\$%^&*()"));
    });

    test('devrait gérer un objet data vide', () {
      // Arrange
      final event = HistoryEvent(
        id: 'empty_data',
        type: EventType.temperature,
        title: 'Test',
        description: 'Test avec data vide',
        timestamp: DateTime.now(),
        data: {},
      );

      // Act
      final firestoreData = event.toFirestore();

      // Assert
      expect(firestoreData['data'], isNotNull);
      expect(firestoreData['data'], isEmpty);
    });

    test('devrait gérer des valeurs nulles dans data', () {
      // Arrange
      final event = HistoryEvent(
        id: 'null_values',
        type: EventType.modeChange,
        title: 'Test',
        description: 'Test avec valeurs null',
        timestamp: DateTime.now(),
        data: {
          'value1': null,
          'value2': 'not null',
          'value3': null,
        },
      );

      // Act
      final firestoreData = event.toFirestore();

      // Assert
      expect(firestoreData['data']['value1'], isNull);
      expect(firestoreData['data']['value2'], equals('not null'));
      expect(firestoreData['data']['value3'], isNull);
    });
  });
}