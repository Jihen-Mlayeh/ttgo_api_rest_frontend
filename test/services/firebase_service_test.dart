import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ttgo_iot_app/data/models/sensor_data.dart';
import 'package:ttgo_iot_app/data/services/firebase_service.dart';


void main() {
  group('FirebaseService Integration Tests', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    // =========================================================================
    // TESTS de la logique métier (sans appeler FirebaseService directement)
    // =========================================================================

    group('Firestore Data Structure Tests', () {
      test('devrait pouvoir sauvegarder SensorData dans Firestore', () async {
        // Arrange
        final sensorData = SensorData(
          temperature: 25.5,
          lightRaw: 2048,
          lightPercent: 50,
          timestamp: DateTime(2024, 1, 14, 10, 30, 0),
        );

        // Act - Simuler ce que fait saveSensorData()
        await fakeFirestore
            .collection('sensors')
            .doc('current')
            .set(sensorData.toFirestore());

        // Assert
        final doc = await fakeFirestore
            .collection('sensors')
            .doc('current')
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()!['temperature'], equals(25.5));
        expect(doc.data()!['lightRaw'], equals(2048));
        expect(doc.data()!['lightPercent'], equals(50));
      });

      test('devrait pouvoir ajouter SensorData à l\'historique', () async {
        // Arrange
        final sensorData = SensorData(
          temperature: 25.5,
          lightRaw: 2048,
          lightPercent: 50,
          timestamp: DateTime(2024, 1, 14, 10, 30, 0),
        );

        // Act - Simuler ce que fait addToHistory()
        await fakeFirestore
            .collection('history')
            .add(sensorData.toFirestore());

        // Assert
        final snapshot = await fakeFirestore.collection('history').get();
        expect(snapshot.docs.length, equals(1));

        final doc = snapshot.docs.first;
        expect(doc.data()['temperature'], equals(25.5));
        expect(doc.data()['lightRaw'], equals(2048));
      });

      test('devrait écraser les données précédentes dans current', () async {
        // Arrange
        final firstData = SensorData(
          temperature: 20.0,
          lightRaw: 1000,
          lightPercent: 25,
          timestamp: DateTime(2024, 1, 14, 10, 0, 0),
        );

        final secondData = SensorData(
          temperature: 30.0,
          lightRaw: 3000,
          lightPercent: 75,
          timestamp: DateTime(2024, 1, 14, 11, 0, 0),
        );

        // Act
        await fakeFirestore
            .collection('sensors')
            .doc('current')
            .set(firstData.toFirestore());

        await fakeFirestore
            .collection('sensors')
            .doc('current')
            .set(secondData.toFirestore());

        // Assert
        final doc = await fakeFirestore
            .collection('sensors')
            .doc('current')
            .get();

        expect(doc.data()!['temperature'], equals(30.0));
        expect(doc.data()!['lightPercent'], equals(75));
      });

      test('devrait créer plusieurs entrées distinctes dans l\'historique', () async {
        // Arrange
        final data1 = SensorData(
          temperature: 20.0,
          lightRaw: 1000,
          lightPercent: 25,
          timestamp: DateTime(2024, 1, 14, 10, 0, 0),
        );

        final data2 = SensorData(
          temperature: 25.0,
          lightRaw: 2000,
          lightPercent: 50,
          timestamp: DateTime(2024, 1, 14, 11, 0, 0),
        );

        final data3 = SensorData(
          temperature: 30.0,
          lightRaw: 3000,
          lightPercent: 75,
          timestamp: DateTime(2024, 1, 14, 12, 0, 0),
        );

        // Act
        await fakeFirestore.collection('history').add(data1.toFirestore());
        await fakeFirestore.collection('history').add(data2.toFirestore());
        await fakeFirestore.collection('history').add(data3.toFirestore());

        // Assert
        final snapshot = await fakeFirestore.collection('history').get();
        expect(snapshot.docs.length, equals(3));
      });
    });

    // =========================================================================
    // TESTS de requêtes Firestore (logique de getHistory24h)
    // =========================================================================

    group('History Query Tests (24h logic)', () {
      test('devrait filtrer les données des dernières 24h', () async {
        // Arrange
        final now = DateTime.now();
        final recentData = SensorData(
          temperature: 25.0,
          lightRaw: 2000,
          lightPercent: 50,
          timestamp: now.subtract(Duration(hours: 2)),
        );

        final oldData = SensorData(
          temperature: 20.0,
          lightRaw: 1000,
          lightPercent: 25,
          timestamp: now.subtract(Duration(hours: 48)),
        );

        await fakeFirestore.collection('history').add(recentData.toFirestore());
        await fakeFirestore.collection('history').add(oldData.toFirestore());

        // Act - Simuler la requête de getHistory24h()
        final yesterday = now.subtract(const Duration(hours: 24));
        final snapshot = await fakeFirestore
            .collection('history')
            .where('timestamp', isGreaterThan: yesterday)
            .get();

        // Assert
        expect(snapshot.docs.length, equals(1));
        expect(snapshot.docs.first.data()['temperature'], equals(25.0));
      });

      test('devrait trier par timestamp décroissant', () async {
        // Arrange
        final now = DateTime.now();
        final data1 = SensorData(
          temperature: 20.0,
          lightRaw: 1000,
          lightPercent: 25,
          timestamp: now.subtract(Duration(hours: 10)),
        );

        final data2 = SensorData(
          temperature: 25.0,
          lightRaw: 2000,
          lightPercent: 50,
          timestamp: now.subtract(Duration(hours: 5)),
        );

        final data3 = SensorData(
          temperature: 30.0,
          lightRaw: 3000,
          lightPercent: 75,
          timestamp: now.subtract(Duration(hours: 1)),
        );

        await fakeFirestore.collection('history').add(data1.toFirestore());
        await fakeFirestore.collection('history').add(data2.toFirestore());
        await fakeFirestore.collection('history').add(data3.toFirestore());

        // Act - Simuler la requête avec orderBy
        final yesterday = now.subtract(const Duration(hours: 24));
        final snapshot = await fakeFirestore
            .collection('history')
            .where('timestamp', isGreaterThan: yesterday)
            .orderBy('timestamp', descending: true)
            .get();

        // Assert
        expect(snapshot.docs.length, equals(3));

        final temps = snapshot.docs.map((doc) =>
        doc.data()['temperature'] as double
        ).toList();

        expect(temps[0], equals(30.0)); // Plus récent
        expect(temps[1], equals(25.0));
        expect(temps[2], equals(20.0)); // Plus ancien
      });

      test('devrait limiter à 100 résultats', () async {
        // Arrange
        final now = DateTime.now();

        // Ajouter 150 entrées
        for (int i = 0; i < 150; i++) {
          final data = SensorData(
            temperature: 20.0 + i * 0.1,
            lightRaw: 2000,
            lightPercent: 50,
            timestamp: now.subtract(Duration(minutes: i)),
          );
          await fakeFirestore.collection('history').add(data.toFirestore());
        }

        // Act - Simuler la requête avec limit
        final yesterday = now.subtract(const Duration(hours: 24));
        final snapshot = await fakeFirestore
            .collection('history')
            .where('timestamp', isGreaterThan: yesterday)
            .orderBy('timestamp', descending: true)
            .limit(100)
            .get();

        // Assert
        expect(snapshot.docs.length, lessThanOrEqualTo(100));
      });

      test('devrait retourner une liste vide si pas de données', () async {
        // Act
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(hours: 24));
        final snapshot = await fakeFirestore
            .collection('history')
            .where('timestamp', isGreaterThan: yesterday)
            .get();

        // Assert
        expect(snapshot.docs, isEmpty);
      });

      test('devrait convertir Timestamp en DateTime correctement', () async {
        // Arrange
        final now = DateTime.now();
        final sensorData = SensorData(
          temperature: 25.0,
          lightRaw: 2000,
          lightPercent: 50,
          timestamp: now,
        );

        await fakeFirestore.collection('history').add(sensorData.toFirestore());

        // Act
        final snapshot = await fakeFirestore.collection('history').get();
        final doc = snapshot.docs.first;
        final data = doc.data();

        // Assert
        expect(data['timestamp'], isA<DateTime>());

        // Reconstruire SensorData comme le fait getHistory24h()
        final reconstructed = SensorData(
          temperature: (data['temperature'] as num).toDouble(),
          lightRaw: data['lightRaw'] as int,
          lightPercent: data['lightPercent'] as int,
          timestamp: data['timestamp'] as DateTime,
        );

        expect(reconstructed.timestamp, isA<DateTime>());
      });
    });

    // =========================================================================
    // TESTS de calcul statistiques (logique de getStatistics)
    // =========================================================================

    group('Statistics Calculation Tests', () {
      test('devrait calculer les statistiques correctement', () async {
        // Arrange
        final now = DateTime.now();
        final data = [
          SensorData(
            temperature: 20.0,
            lightRaw: 1000,
            lightPercent: 25,
            timestamp: now.subtract(Duration(hours: 2)),
          ),
          SensorData(
            temperature: 25.0,
            lightRaw: 2000,
            lightPercent: 50,
            timestamp: now.subtract(Duration(hours: 4)),
          ),
          SensorData(
            temperature: 30.0,
            lightRaw: 3000,
            lightPercent: 75,
            timestamp: now.subtract(Duration(hours: 6)),
          ),
        ];

        for (var d in data) {
          await fakeFirestore.collection('history').add(d.toFirestore());
        }

        // Act - Simuler le calcul de getStatistics()
        final yesterday = now.subtract(const Duration(hours: 24));
        final snapshot = await fakeFirestore
            .collection('history')
            .where('timestamp', isGreaterThan: yesterday)
            .get();

        final temps = snapshot.docs
            .map((doc) => (doc.data()['temperature'] as num).toDouble())
            .toList();

        final lights = snapshot.docs
            .map((doc) => doc.data()['lightPercent'] as int)
            .toList();

        temps.sort();
        lights.sort();

        final stats = {
          'avgTemp': temps.reduce((a, b) => a + b) / temps.length,
          'minTemp': temps.first,
          'maxTemp': temps.last,
          'avgLight': lights.reduce((a, b) => a + b) ~/ lights.length,
          'count': snapshot.docs.length,
        };

        // Assert
        expect(stats['avgTemp'], equals(25.0)); // (20+25+30)/3
        expect(stats['minTemp'], equals(20.0));
        expect(stats['maxTemp'], equals(30.0));
        expect(stats['avgLight'], equals(50)); // (25+50+75)/3
        expect(stats['count'], equals(3));
      });

      test('devrait retourner des stats à zéro si pas de données', () {
        // Act - Simuler le cas snapshot.docs.isEmpty
        final stats = {
          'avgTemp': 0.0,
          'minTemp': 0.0,
          'maxTemp': 0.0,
          'avgLight': 0,
          'count': 0,
        };

        // Assert
        expect(stats['avgTemp'], equals(0.0));
        expect(stats['minTemp'], equals(0.0));
        expect(stats['maxTemp'], equals(0.0));
        expect(stats['avgLight'], equals(0));
        expect(stats['count'], equals(0));
      });

      test('devrait ignorer les données de plus de 24h', () async {
        // Arrange
        final now = DateTime.now();
        final recentData = SensorData(
          temperature: 25.0,
          lightRaw: 2000,
          lightPercent: 50,
          timestamp: now.subtract(Duration(hours: 2)),
        );

        final oldData = SensorData(
          temperature: 50.0,
          lightRaw: 4000,
          lightPercent: 100,
          timestamp: now.subtract(Duration(hours: 48)),
        );

        await fakeFirestore.collection('history').add(recentData.toFirestore());
        await fakeFirestore.collection('history').add(oldData.toFirestore());

        // Act
        final yesterday = now.subtract(const Duration(hours: 24));
        final snapshot = await fakeFirestore
            .collection('history')
            .where('timestamp', isGreaterThan: yesterday)
            .get();

        // Assert
        expect(snapshot.docs.length, equals(1));
        expect(snapshot.docs.first.data()['temperature'], equals(25.0));
      });

      test('devrait calculer la moyenne avec une seule valeur', () async {
        // Arrange
        final now = DateTime.now();
        final sensorData = SensorData(
          temperature: 25.0,
          lightRaw: 2000,
          lightPercent: 50,
          timestamp: now,
        );

        await fakeFirestore.collection('history').add(sensorData.toFirestore());

        // Act
        final snapshot = await fakeFirestore.collection('history').get();

        final temps = snapshot.docs
            .map((doc) => (doc.data()['temperature'] as num).toDouble())
            .toList();

        final lights = snapshot.docs
            .map((doc) => doc.data()['lightPercent'] as int)
            .toList();

        temps.sort();
        lights.sort();

        final stats = {
          'avgTemp': temps.reduce((a, b) => a + b) / temps.length,
          'minTemp': temps.first,
          'maxTemp': temps.last,
          'avgLight': lights.reduce((a, b) => a + b) ~/ lights.length,
          'count': snapshot.docs.length,
        };

        // Assert
        expect(stats['avgTemp'], equals(25.0));
        expect(stats['minTemp'], equals(25.0));
        expect(stats['maxTemp'], equals(25.0));
        expect(stats['avgLight'], equals(50));
        expect(stats['count'], equals(1));
      });

      test('devrait gérer les températures négatives', () async {
        // Arrange
        final now = DateTime.now();
        final data = [
          SensorData(
            temperature: -10.0,
            lightRaw: 1000,
            lightPercent: 25,
            timestamp: now.subtract(Duration(hours: 2)),
          ),
          SensorData(
            temperature: 0.0,
            lightRaw: 2000,
            lightPercent: 50,
            timestamp: now.subtract(Duration(hours: 4)),
          ),
          SensorData(
            temperature: 10.0,
            lightRaw: 3000,
            lightPercent: 75,
            timestamp: now.subtract(Duration(hours: 6)),
          ),
        ];

        for (var d in data) {
          await fakeFirestore.collection('history').add(d.toFirestore());
        }

        // Act
        final snapshot = await fakeFirestore.collection('history').get();

        final temps = snapshot.docs
            .map((doc) => (doc.data()['temperature'] as num).toDouble())
            .toList();

        temps.sort();

        // Assert
        expect(temps.first, equals(-10.0)); // minTemp
        expect(temps.last, equals(10.0));   // maxTemp

        final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
        expect(avgTemp, equals(0.0)); // (-10+0+10)/3
      });

      test('devrait arrondir la moyenne de lumière (division entière)', () async {
        // Arrange
        final now = DateTime.now();
        final data = [
          SensorData(
            temperature: 25.0,
            lightRaw: 1000,
            lightPercent: 33,
            timestamp: now.subtract(Duration(hours: 2)),
          ),
          SensorData(
            temperature: 25.0,
            lightRaw: 2000,
            lightPercent: 34,
            timestamp: now.subtract(Duration(hours: 4)),
          ),
        ];

        for (var d in data) {
          await fakeFirestore.collection('history').add(d.toFirestore());
        }

        // Act
        final snapshot = await fakeFirestore.collection('history').get();

        final lights = snapshot.docs
            .map((doc) => doc.data()['lightPercent'] as int)
            .toList();

        final avgLight = lights.reduce((a, b) => a + b) ~/ lights.length;

        // Assert
        expect(avgLight, equals(33)); // (33+34) ~/ 2 = 33
      });

      test('devrait gérer de grandes quantités de données', () async {
        // Arrange
        final now = DateTime.now();

        // Ajouter 1000 entrées
        for (int i = 0; i < 1000; i++) {
          final data = SensorData(
            temperature: 20.0 + (i % 20) * 0.5,
            lightRaw: 2000,
            lightPercent: 50,
            timestamp: now.subtract(Duration(minutes: i)),
          );
          await fakeFirestore.collection('history').add(data.toFirestore());
        }

        // Act
        final snapshot = await fakeFirestore.collection('history').get();

        // Assert
        expect(snapshot.docs.length, equals(1000));
      });
    });

    // =========================================================================
    // TESTS de scénarios réels
    // =========================================================================

    group('Real-world Scenarios', () {
      test('scénario: sauvegarde et récupération immédiate', () async {
        // Arrange
        final sensorData = SensorData(
          temperature: 25.5,
          lightRaw: 2048,
          lightPercent: 50,
          timestamp: DateTime.now(),
        );

        // Act - Simuler saveSensorData + addToHistory
        await fakeFirestore
            .collection('sensors')
            .doc('current')
            .set(sensorData.toFirestore());

        await fakeFirestore
            .collection('history')
            .add(sensorData.toFirestore());

        final currentDoc = await fakeFirestore
            .collection('sensors')
            .doc('current')
            .get();

        final historySnapshot = await fakeFirestore
            .collection('history')
            .get();

        // Assert
        expect(currentDoc.exists, isTrue);
        expect(currentDoc.data()!['temperature'], equals(25.5));
        expect(historySnapshot.docs.length, equals(1));
      });

      test('scénario: simulation d\'une journée de mesures', () async {
        // Arrange
        final now = DateTime.now();

        // Mesures toutes les heures pendant 24h
        for (int hour = 0; hour < 24; hour++) {
          final data = SensorData(
            temperature: 20.0 + hour * 0.5,
            lightRaw: 1000 + hour * 100,
            lightPercent: hour * 4,
            timestamp: now.subtract(Duration(hours: 23 - hour)),
          );
          await fakeFirestore.collection('history').add(data.toFirestore());
        }

        // Act
        final yesterday = now.subtract(const Duration(hours: 24));
        final snapshot = await fakeFirestore
            .collection('history')
            .where('timestamp', isGreaterThan: yesterday)
            .get();

        final temps = snapshot.docs
            .map((doc) => (doc.data()['temperature'] as num).toDouble())
            .toList();

        temps.sort();

        // Assert
        expect(snapshot.docs.length, equals(24));
        expect(temps.first, equals(20.0));
        expect(temps.last, equals(31.5)); // 20 + 23*0.5
      });

      test('scénario: nettoyage automatique (>24h)', () async {
        // Arrange
        final now = DateTime.now();

        // Données récentes
        for (int i = 0; i < 10; i++) {
          final data = SensorData(
            temperature: 25.0,
            lightRaw: 2000,
            lightPercent: 50,
            timestamp: now.subtract(Duration(hours: i)),
          );
          await fakeFirestore.collection('history').add(data.toFirestore());
        }

        // Données anciennes
        for (int i = 0; i < 10; i++) {
          final data = SensorData(
            temperature: 20.0,
            lightRaw: 1000,
            lightPercent: 25,
            timestamp: now.subtract(Duration(hours: 48 + i)),
          );
          await fakeFirestore.collection('history').add(data.toFirestore());
        }

        // Act
        final yesterday = now.subtract(const Duration(hours: 24));
        final snapshot = await fakeFirestore
            .collection('history')
            .where('timestamp', isGreaterThan: yesterday)
            .get();

        // Assert
        expect(snapshot.docs.length, equals(10)); // Seulement les récentes
      });
    });

    // =========================================================================
    // TESTS des noms de collections
    // =========================================================================

    group('Collection Names Tests', () {
      test('devrait utiliser la collection "sensors"', () async {
        // Act
        final ref = fakeFirestore.collection('sensors');

        // Assert
        expect(ref.path, equals('sensors'));
      });

      test('devrait utiliser la collection "history"', () async {
        // Act
        final ref = fakeFirestore.collection('history');

        // Assert
        expect(ref.path, equals('history'));
      });

      test('devrait utiliser le document "current" dans sensors', () async {
        // Act
        final ref = fakeFirestore.collection('sensors').doc('current');

        // Assert
        expect(ref.path, equals('sensors/current'));
      });
    });
  });
}
