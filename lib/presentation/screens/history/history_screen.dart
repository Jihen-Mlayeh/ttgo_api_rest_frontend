import 'package:flutter/material.dart';
import 'dart:math';
import '../../../data/services/csv_export_service.dart';
import '../../widgets/export_dialog.dart';
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
      final type = EventType.values[random.nextInt(EventType.values.length)];
      final timestamp =
      now.subtract(Duration(hours: index * 2 + random.nextInt(2)));

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
        return 'Température mesurée : ${(20 + random.nextDouble() * 15).toStringAsFixed(1)}°C';
      case EventType.light:
        return 'Luminosité mesurée : ${30 + random.nextInt(70)}%';
      case EventType.ledOn:
        return 'La LED a été allumée';
      case EventType.ledOff:
        return 'La LED a été éteinte';
      case EventType.modeChange:
        return 'Mode changé';
      case EventType.thresholdChange:
        return 'Les seuils ont été modifiés';
    }
  }

  Map<String, dynamic>? _getDataForType(EventType type, Random random) {
    switch (type) {
      case EventType.temperature:
        return {'value': 20 + random.nextDouble() * 15, 'unit': '°C'};
      case EventType.light:
        return {'value': 30 + random.nextInt(70), 'unit': '%'};
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exporter en CSV',
                onPressed: _exportToCsv,
              ),
              if (filteredEvents.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      filteredEvents.length > 99
                          ? '99+'
                          : '${filteredEvents.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: filteredEvents.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
                setState(_generateMockEvents);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  return TimelineItem(
                    event: filteredEvents[index],
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

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                    'Tous', _filterType == null, () => _filterType = null),
                const SizedBox(width: 8),
                ...EventType.values.map(
                      (type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      _getEventTypeLabel(type),
                      _filterType == type,
                          () => _filterType = type,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(onTap),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Aucun événement trouvé'),
        ],
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
      if (_searchQuery.isNotEmpty &&
          !event.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) &&
          !event.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_filterType != null && event.type != _filterType) return false;
      if (_filterDate != null &&
          !_isSameDay(event.timestamp, _filterDate!)) return false;
      return true;
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _exportToCsv() {
    final filteredEvents = _getFilteredEvents();
    if (filteredEvents.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => ExportDialog(
        eventCount: filteredEvents.length,
        onConfirm: () {
          CsvExportService.exportEventsToCsv(filteredEvents);
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
