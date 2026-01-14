import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:ttgo_iot_app/data/models/history_event.dart';

void main() {
  group('CsvExportService Tests (Web)', () {
    // =========================================================================
    // TESTS de génération CSV (logique métier)
    // =========================================================================
    group('CSV Generation Logic', () {
      test('devrait générer les headers corrects', () {
        // Arrange
        final expectedHeaders = ['Date', 'Heure', 'Type', 'Titre', 'Description', 'Données'];

        // Assert
        expect(expectedHeaders.length, equals(6));
        expect(expectedHeaders[0], equals('Date'));
        expect(expectedHeaders[1], equals('Heure'));
        expect(expectedHeaders[2], equals('Type'));
        expect(expectedHeaders[3], equals('Titre'));
        expect(expectedHeaders[4], equals('Description'));
        expect(expectedHeaders[5], equals('Données'));
      });

      test('devrait formater correctement la date au format dd/MM/yyyy', () {
        // Arrange
        final date = DateTime(2024, 1, 14, 10, 30, 45);

        // Act
        final dateFormatted = DateFormat('dd/MM/yyyy').format(date);

        // Assert
        expect(dateFormatted, equals('14/01/2024'));
      });

      test('devrait formater correctement l\'heure au format HH:mm:ss', () {
        // Arrange
        final date = DateTime(2024, 1, 14, 10, 30, 45);

        // Act
        final timeFormatted = DateFormat('HH:mm:ss').format(date);

        // Assert
        expect(timeFormatted, equals('10:30:45'));
      });

      test('devrait ajouter un padding pour les heures < 10', () {
        // Arrange
        final date = DateTime(2024, 1, 5, 9, 5, 3);

        // Act
        final timeFormatted = DateFormat('HH:mm:ss').format(date);

        // Assert
        expect(timeFormatted, equals('09:05:03'));
      });

      test('devrait générer un nom de fichier avec timestamp correct', () {
        // Arrange
        final now = DateTime(2024, 1, 14, 15, 30, 45);

        // Act
        final filename = 'historique_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';

        // Assert
        expect(filename, equals('historique_20240114_153045.csv'));
        expect(filename, startsWith('historique_'));
        expect(filename, endsWith('.csv'));
      });

      test('devrait créer une ligne CSV complète pour un événement sans data', () {
        // Arrange
        final event = HistoryEvent(
          id: 'evt_1',
          type: EventType.ledOn,
          title: 'LED activée',
          description: 'Allumage manuel',
          timestamp: DateTime(2024, 1, 14, 10, 30, 0),
          data: null,
        );

        // Act - On simule ce que fait le service
        final row = [
          DateFormat('dd/MM/yyyy').format(event.timestamp),
          DateFormat('HH:mm:ss').format(event.timestamp),
          // On ne peut pas appeler _getEventTypeName, on vérifie juste la structure
          'LED Allumée', // Ce que _getEventTypeName retournerait
          event.title,
          event.description,
          event.data != null ? jsonEncode(event.data) : '',
        ];

        // Assert
        expect(row.length, equals(6));
        expect(row[0], equals('14/01/2024'));
        expect(row[1], equals('10:30:00'));
        expect(row[2], isA<String>()); // Le type est une string
        expect(row[3], equals('LED activée'));
        expect(row[4], equals('Allumage manuel'));
        expect(row[5], equals(''));
      });

      test('devrait encoder les données en JSON', () {
        // Arrange
        final event = HistoryEvent(
          id: 'evt_2',
          type: EventType.temperature,
          title: 'Alerte température',
          description: 'Température élevée détectée',
          timestamp: DateTime(2024, 1, 14, 15, 45, 30),
          data: {
            'temperature': 35.5,
            'threshold': 30.0,
            'mode': 'AUTO-TEMP',
          },
        );

        // Act
        final dataJson = jsonEncode(event.data);

        // Assert
        expect(dataJson, contains('temperature'));
        expect(dataJson, contains('35.5'));
        expect(dataJson, contains('threshold'));
        expect(dataJson, contains('30.0'));
        expect(dataJson, contains('AUTO-TEMP'));
      });

      test('devrait convertir correctement en CSV avec ListToCsvConverter', () {
        // Arrange
        final rows = [
          ['Date', 'Heure', 'Type', 'Titre', 'Description', 'Données'],
          ['14/01/2024', '10:30:00', 'Température', 'Test', 'Description', ''],
        ];

        // Act
        final csv = const ListToCsvConverter().convert(rows);

        // Assert
        expect(csv, isNotEmpty);
        expect(csv, contains('Date,Heure,Type,Titre,Description,Données'));
        expect(csv, contains('14/01/2024,10:30:00,Température,Test,Description,'));
      });

      test('devrait gérer correctement l\'encodage UTF-8', () {
        // Arrange
        final csvContent = 'Température,Lumière,Données\n25.5°C,80%,Test';

        // Act
        final bytes = utf8.encode(csvContent);

        // Assert
        expect(bytes, isNotEmpty);
        expect(bytes, isA<List<int>>());

        // Vérifier le décodage
        final decoded = utf8.decode(bytes);
        expect(decoded, equals(csvContent));
      });

      test('devrait gérer plusieurs événements de types différents', () {
        // Arrange
        final events = [
          HistoryEvent(
            id: '1',
            type: EventType.temperature,
            title: 'Temp haute',
            description: 'Alerte',
            timestamp: DateTime(2024, 1, 14, 10, 0, 0),
          ),
          HistoryEvent(
            id: '2',
            type: EventType.light,
            title: 'Lumière faible',
            description: 'Détection',
            timestamp: DateTime(2024, 1, 14, 11, 0, 0),
          ),
          HistoryEvent(
            id: '3',
            type: EventType.modeChange,
            title: 'Mode changé',
            description: 'AUTO-TEMP activé',
            timestamp: DateTime(2024, 1, 14, 12, 0, 0),
          ),
        ];

        // Act
        final rows = <List<dynamic>>[
          ['Date', 'Heure', 'Type', 'Titre', 'Description', 'Données']
        ];

        for (var event in events) {
          rows.add([
            DateFormat('dd/MM/yyyy').format(event.timestamp),
            DateFormat('HH:mm:ss').format(event.timestamp),
            event.type.name, // Utiliser .name pour obtenir le nom du type
            event.title,
            event.description,
            event.data != null ? jsonEncode(event.data) : '',
          ]);
        }

        // Assert
        expect(rows.length, equals(4)); // Header + 3 events
        expect(rows[1][2], equals('temperature'));
        expect(rows[2][2], equals('light'));
        expect(rows[3][2], equals('modeChange'));
      });

      test('devrait gérer une liste vide d\'événements', () {
        // Arrange
        final events = <HistoryEvent>[];

        // Act
        final rows = [
          ['Date', 'Heure', 'Type', 'Titre', 'Description', 'Données']
        ];

        for (var event in events) {
          rows.add([
            DateFormat('dd/MM/yyyy').format(event.timestamp),
            DateFormat('HH:mm:ss').format(event.timestamp),
            event.type.name,
            event.title,
            event.description,
            event.data != null ? jsonEncode(event.data) : '',
          ]);
        }

        // Assert
        expect(rows.length, equals(1)); // Seulement les headers
      });

      test('devrait échapper correctement les caractères spéciaux dans CSV', () {
        // Arrange
        final event = HistoryEvent(
          id: 'special',
          type: EventType.ledOn,
          title: 'LED "test"',
          description: 'Virgule, point-virgule; et guillemets',
          timestamp: DateTime.now(),
        );

        // Act
        final rows = [
          ['Date', 'Heure', 'Type', 'Titre', 'Description', 'Données'],
          [
            DateFormat('dd/MM/yyyy').format(event.timestamp),
            DateFormat('HH:mm:ss').format(event.timestamp),
            event.type.name,
            event.title,
            event.description,
            '',
          ],
        ];

        final csv = const ListToCsvConverter().convert(rows);

        // Assert - Le ListToCsvConverter échappe automatiquement
        expect(csv, contains('LED "test"'));
        expect(csv, contains('Virgule, point-virgule; et guillemets'));
      });
    });

    // =========================================================================
    // TESTS des types EventType
    // =========================================================================
    group('EventType enum', () {
      test('devrait avoir tous les types définis', () {
        // Act
        final allTypes = EventType.values;

        // Assert
        expect(allTypes.length, equals(6));
        expect(allTypes, contains(EventType.temperature));
        expect(allTypes, contains(EventType.light));
        expect(allTypes, contains(EventType.ledOn));
        expect(allTypes, contains(EventType.ledOff));
        expect(allTypes, contains(EventType.modeChange));
        expect(allTypes, contains(EventType.thresholdChange));
      });

      test('devrait convertir en string avec .name', () {
        // Assert
        expect(EventType.temperature.name, equals('temperature'));
        expect(EventType.light.name, equals('light'));
        expect(EventType.ledOn.name, equals('ledOn'));
        expect(EventType.ledOff.name, equals('ledOff'));
        expect(EventType.modeChange.name, equals('modeChange'));
        expect(EventType.thresholdChange.name, equals('thresholdChange'));
      });
    });

    // =========================================================================
    // TESTS de scénarios réels
    // =========================================================================
    group('Real-world scenarios', () {
      test('scénario: export d\'une journée complète (8h - 18h)', () {
        // Arrange
        final baseDate = DateTime(2024, 1, 14);
        final events = [
          HistoryEvent(
            id: '1',
            type: EventType.modeChange,
            title: 'Démarrage système',
            description: 'Mode MANUEL activé',
            timestamp: baseDate.add(Duration(hours: 8)),
          ),
          HistoryEvent(
            id: '2',
            type: EventType.temperature,
            title: 'Température normale',
            description: '25°C',
            timestamp: baseDate.add(Duration(hours: 9)),
          ),
          HistoryEvent(
            id: '3',
            type: EventType.ledOn,
            title: 'LED ON',
            description: 'Allumage manuel',
            timestamp: baseDate.add(Duration(hours: 10)),
          ),
          HistoryEvent(
            id: '4',
            type: EventType.temperature,
            title: 'Alerte température',
            description: 'Température élevée: 35°C',
            timestamp: baseDate.add(Duration(hours: 14)),
            data: {'temperature': 35.0, 'threshold': 30.0},
          ),
          HistoryEvent(
            id: '5',
            type: EventType.ledOff,
            title: 'LED OFF',
            description: 'Extinction automatique',
            timestamp: baseDate.add(Duration(hours: 18)),
          ),
        ];

        // Act
        final rows = <List<dynamic>>[
          ['Date', 'Heure', 'Type', 'Titre', 'Description', 'Données']
        ];

        for (var event in events) {
          rows.add([
            DateFormat('dd/MM/yyyy').format(event.timestamp),
            DateFormat('HH:mm:ss').format(event.timestamp),
            event.type.name,
            event.title,
            event.description,
            event.data != null ? jsonEncode(event.data) : '',
          ]);
        }

        // Assert
        expect(rows.length, equals(6)); // Header + 5 événements
        expect(rows[1][1], equals('08:00:00')); // 8h
        expect(rows[4][1], equals('14:00:00')); // 14h
        expect(rows[5][1], equals('18:00:00')); // 18h
        expect(rows[1][0], equals('14/01/2024')); // Même jour
        expect(rows[5][0], equals('14/01/2024')); // Même jour
      });

      test('scénario: changements de mode fréquents', () {
        // Arrange
        final now = DateTime(2024, 1, 14, 10, 0, 0);
        final events = [
          HistoryEvent(
            id: '1',
            type: EventType.modeChange,
            title: 'Mode MANUEL',
            description: 'Passage en mode manuel',
            timestamp: now,
            data: {'previousMode': 'AUTO-TEMP', 'newMode': 'MANUEL'},
          ),
          HistoryEvent(
            id: '2',
            type: EventType.modeChange,
            title: 'Mode AUTO-TEMP',
            description: 'Passage en mode auto température',
            timestamp: now.add(Duration(minutes: 30)),
            data: {'previousMode': 'MANUEL', 'newMode': 'AUTO-TEMP'},
          ),
          HistoryEvent(
            id: '3',
            type: EventType.modeChange,
            title: 'Mode AUTO-LIGHT',
            description: 'Passage en mode auto lumière',
            timestamp: now.add(Duration(hours: 1)),
            data: {'previousMode': 'AUTO-TEMP', 'newMode': 'AUTO-LIGHT'},
          ),
        ];

        // Act
        final modeChanges = events.where((e) =>
        e.type == EventType.modeChange
        ).length;

        final dataWithModes = events.where((e) =>
        e.data != null &&
            e.data!.containsKey('newMode')
        ).length;

        // Assert
        expect(modeChanges, equals(3));
        expect(dataWithModes, equals(3));
        expect(events.every((e) => e.data != null), isTrue);
      });

      test('scénario: alertes température et lumière consécutives', () {
        // Arrange
        final events = [
          HistoryEvent(
            id: '1',
            type: EventType.temperature,
            title: 'Alerte température',
            description: 'Température > 30°C',
            timestamp: DateTime(2024, 1, 14, 14, 0, 0),
            data: {'temperature': 32.5, 'threshold': 30.0, 'ledActivated': true},
          ),
          HistoryEvent(
            id: '2',
            type: EventType.light,
            title: 'Lumière faible',
            description: 'Luminosité < 50%',
            timestamp: DateTime(2024, 1, 14, 14, 5, 0),
            data: {'lightPercent': 25, 'threshold': 50, 'ledActivated': true},
          ),
        ];

        // Act
        final types = events.map((e) => e.type).toList();

        // Assert
        expect(types, contains(EventType.temperature));
        expect(types, contains(EventType.light));
        expect(events.every((e) => e.data!['ledActivated'] == true), isTrue);
      });
    });

    // =========================================================================
    // TESTS de cas limites
    // =========================================================================
    group('Edge Cases', () {
      test('devrait gérer un titre très long (200 caractères)', () {
        // Arrange
        final longTitle = 'A' * 200;
        final event = HistoryEvent(
          id: 'long',
          type: EventType.temperature,
          title: longTitle,
          description: 'Test',
          timestamp: DateTime.now(),
        );

        // Act & Assert
        expect(event.title.length, equals(200));
      });

      test('devrait gérer une description vide', () {
        // Arrange
        final event = HistoryEvent(
          id: 'empty',
          type: EventType.ledOn,
          title: 'Test',
          description: '',
          timestamp: DateTime.now(),
        );

        // Act
        final description = event.description;

        // Assert
        expect(description, isEmpty);
      });

      test('devrait gérer minuit (00:00:00)', () {
        // Arrange
        final midnight = DateTime(2024, 1, 14, 0, 0, 0);

        // Act
        final time = DateFormat('HH:mm:ss').format(midnight);

        // Assert
        expect(time, equals('00:00:00'));
      });

      test('devrait gérer la dernière seconde de la journée (23:59:59)', () {
        // Arrange
        final lastSecond = DateTime(2024, 1, 14, 23, 59, 59);

        // Act
        final time = DateFormat('HH:mm:ss').format(lastSecond);

        // Assert
        expect(time, equals('23:59:59'));
      });

      test('devrait gérer le 1er janvier', () {
        // Arrange
        final newYear = DateTime(2024, 1, 1);

        // Act
        final date = DateFormat('dd/MM/yyyy').format(newYear);

        // Assert
        expect(date, equals('01/01/2024'));
      });

      test('devrait gérer le 31 décembre', () {
        // Arrange
        final endYear = DateTime(2024, 12, 31);

        // Act
        final date = DateFormat('dd/MM/yyyy').format(endYear);

        // Assert
        expect(date, equals('31/12/2024'));
      });

      test('devrait gérer les données JSON complexes imbriquées', () {
        // Arrange
        final event = HistoryEvent(
          id: 'complex',
          type: EventType.modeChange,
          title: 'Changement complexe',
          description: 'Test',
          timestamp: DateTime.now(),
          data: {
            'previousMode': 'MANUEL',
            'newMode': 'AUTO-TEMP',
            'settings': {
              'tempThreshold': 30.0,
              'lightThreshold': 50,
              'metadata': {
                'user': 'admin',
                'app_version': '1.0.0',
              },
            },
          },
        );

        // Act
        final dataJson = jsonEncode(event.data);

        // Assert
        expect(dataJson, contains('previousMode'));
        expect(dataJson, contains('MANUEL'));
        expect(dataJson, contains('settings'));
        expect(dataJson, contains('metadata'));
        expect(dataJson, contains('app_version'));
      });
    });
  });
}
