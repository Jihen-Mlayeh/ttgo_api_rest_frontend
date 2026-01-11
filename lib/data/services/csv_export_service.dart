import 'dart:convert';
import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/history_event.dart';

class CsvExportService {
  static void exportEventsToCsv(List<HistoryEvent> events) {
    // Créer les headers
    List<List<dynamic>> rows = [
      ['Date', 'Heure', 'Type', 'Titre', 'Description', 'Données']
    ];

    // Ajouter les données
    for (var event in events) {
      rows.add([
        DateFormat('dd/MM/yyyy').format(event.timestamp),
        DateFormat('HH:mm:ss').format(event.timestamp),
        _getEventTypeName(event.type),
        event.title,
        event.description,
        event.data != null ? jsonEncode(event.data) : '',
      ]);
    }

    // Convertir en CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Créer le blob et télécharger
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'historique_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  static String _getEventTypeName(EventType type) {
    switch (type) {
      case EventType.temperature:
        return 'Température';
      case EventType.light:
        return 'Lumière';
      case EventType.ledOn:
        return 'LED Allumée';
      case EventType.ledOff:
        return 'LED Éteinte';
      case EventType.modeChange:
        return 'Changement Mode';
      case EventType.thresholdChange:
        return 'Changement Seuil';
    }
  }
}