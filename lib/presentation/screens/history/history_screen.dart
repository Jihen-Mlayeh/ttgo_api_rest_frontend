import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../widgets/timeline_item.dart';
import '../../../data/models/history_event.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  EventType? _filterType;
  DateTime? _filterDate;

  // Données de test (mock)
  late List<HistoryEvent> _events;

  @override
  void initState() {
    super.initState();
    _generateMockEvents();
  }

  void _generateMockEvents() {
    final random = Random();
    final now = DateTime.now();

    _events = List.generate(30, (index) {
      final types = EventType.values;
      final type = types[random.nextInt(types.length)];
      final timestamp = now.subtract(Duration(hours: index * 2 + random.nextInt(2)));

      return HistoryEvent(
        id: 'event_$index',
        type: type,
        title: _getTitleForType(type),
        description: _getDescriptionForType(type, random),
        timestamp: timestamp,
        data: _getDataForType(type, random),
      );
    });

    _events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  String _getTitleForType(EventType type) {
    switch (type) {
      case EventType.temperature:
        return 'Changement de température';
      case EventType.light:
        return 'Changement de luminosité';
      case EventType.ledOn:
        return 'LED allumée';
      case EventType.ledOff:
        return 'LED éteinte';
      case EventType.modeChange:
        return 'Changement de mode';
      case EventType.thresholdChange:
        return 'Modification des seuils';
    }
  }

  String _getDescriptionForType(EventType type, Random random) {
    switch (type) {
      case EventType.temperature:
        final temp = (20 + random.nextDouble() * 15).toStringAsFixed(1);
        return 'Température mesurée : $temp°C';
      case EventType.light:
        final light = 30 + random.nextInt(70);
        return 'Luminosité mesurée : $light%';
      case EventType.ledOn:
        return 'La LED a été allumée';
      case EventType.ledOff:
        return 'La LED a été éteinte';
      case EventType.modeChange:
        final modes = ['MANUEL', 'AUTO-TEMP', 'AUTO-LIGHT'];
        return 'Mode changé vers ${modes[random.nextInt(modes.length)]}';
      case EventType.thresholdChange:
        return 'Les seuils ont été modifiés';
    }
  }

  Map<String, dynamic>? _getDataForType(EventType type, Random random) {
    switch (type) {
      case EventType.temperature:
        return {
          'value': (20 + random.nextDouble() * 15).toStringAsFixed(1),
          'unit': '°C',
        };
      case EventType.light:
        return {
          'value': 30 + random.nextInt(70),
          'unit': '%',
        };
      case EventType.modeChange:
        final modes = ['MANUEL', 'AUTO-TEMP', 'AUTO-LIGHT'];
        return {
          'old_mode': modes[random.nextInt(modes.length)],
          'new_mode': modes[random.nextInt(modes.length)],
        };
      case EventType.thresholdChange:
        return {
          'temperature': (20 + random.nextDouble() * 10).toStringAsFixed(1),
          'light': 30 + random.nextInt(70),
        };
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _getFilteredEvents();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique & Logs'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToCsv,
            tooltip: 'Exporter en CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),

                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'Tous',
                        _filterType == null,
                            () => setState(() => _filterType = null),
                      ),
                      const SizedBox(width: 8),
                      ...EventType.values.map((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            _getEventTypeLabel(type),
                            _filterType == type,
                                () => setState(() => _filterType = type),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Timeline
          Expanded(
            child: filteredEvents.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun événement trouvé',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
                setState(() => _generateMockEvents());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  return TimelineItem(
                    event: event,
                    isFirst: index == 0,
                    isLast: index == filteredEvents.length - 1,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.temperature:
        return 'Température';
      case EventType.light:
        return 'Lumière';
      case EventType.ledOn:
      case EventType.ledOff:
        return 'LED';
      case EventType.modeChange:
        return 'Mode';
      case EventType.thresholdChange:
        return 'Seuils';
    }
  }

  List<HistoryEvent> _getFilteredEvents() {
    return _events.where((event) {
      // Filter by search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!event.title.toLowerCase().contains(query) &&
            !event.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filter by type
      if (_filterType != null && event.type != _filterType) {
        return false;
      }

      // Filter by date
      if (_filterDate != null) {
        if (!_isSameDay(event.timestamp, _filterDate!)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _exportToCsv() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export CSV : Fonctionnalité en développement'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}