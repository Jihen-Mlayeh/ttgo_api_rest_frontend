import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _sensorsCollection = 'sensors';
  final String _historyCollection = 'history';

  Future<void> saveSensorData(SensorData data) async {
    try {
      await _firestore
          .collection(_sensorsCollection)
          .doc('current')
          .set(data.toFirestore());
    } catch (e) {
      print('Erreur sauvegarde Firebase: $e');
    }
  }

  Future<void> addToHistory(SensorData data) async {
    try {
      await _firestore
          .collection(_historyCollection)
          .add(data.toFirestore());
    } catch (e) {
      print('Erreur ajout historique: $e');
    }
  }

  Stream<List<SensorData>> getHistory24h() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    return _firestore
        .collection(_historyCollection)
        .where('timestamp', isGreaterThan: yesterday)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SensorData(
          temperature: (data['temperature'] as num).toDouble(),
          lightRaw: data['lightRaw'] as int,
          lightPercent: data['lightPercent'] as int,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          ledState: data['ledState'] as bool?,
          mode: data['mode'] as String?,
        );
      }).toList();
    });
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      final snapshot = await _firestore
          .collection(_historyCollection)
          .where('timestamp', isGreaterThan: yesterday)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'avgTemp': 0.0,
          'minTemp': 0.0,
          'maxTemp': 0.0,
          'avgLight': 0,
          'count': 0,
        };
      }

      final temps = snapshot.docs
          .map((doc) => (doc.data()['temperature'] as num).toDouble())
          .toList();

      final lights = snapshot.docs
          .map((doc) => doc.data()['lightPercent'] as int)
          .toList();

      temps.sort();
      lights.sort();

      return {
        'avgTemp': temps.reduce((a, b) => a + b) / temps.length,
        'minTemp': temps.first,
        'maxTemp': temps.last,
        'avgLight': lights.reduce((a, b) => a + b) ~/ lights.length,
        'count': snapshot.docs.length,
      };
    } catch (e) {
      print('Erreur statistiques: $e');
      return {
        'avgTemp': 0.0,
        'minTemp': 0.0,
        'maxTemp': 0.0,
        'avgLight': 0,
        'count': 0,
      };
    }
  }
}