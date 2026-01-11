enum EventType {
  temperature,
  light,
  ledOn,
  ledOff,
  modeChange,
  thresholdChange,
}

class HistoryEvent {
  final String id;
  final EventType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  HistoryEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.data,
  });

  factory HistoryEvent.fromFirestore(Map<String, dynamic> doc, String id) {
    return HistoryEvent(
      id: id,
      type: _parseEventType(doc['type'] as String),
      title: doc['title'] as String,
      description: doc['description'] as String,
      timestamp: (doc['timestamp'] as dynamic).toDate(),
      data: doc['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'data': data,
    };
  }

  static EventType _parseEventType(String type) {
    switch (type) {
      case 'temperature':
        return EventType.temperature;
      case 'light':
        return EventType.light;
      case 'ledOn':
        return EventType.ledOn;
      case 'ledOff':
        return EventType.ledOff;
      case 'modeChange':
        return EventType.modeChange;
      case 'thresholdChange':
        return EventType.thresholdChange;
      default:
        return EventType.temperature;
    }
  }
}