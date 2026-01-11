import 'package:flutter/material.dart';
import '../../../data/services/firebase_service.dart';
import '../../../data/models/sensor_data.dart';
import '../../widgets/temperature_chart.dart';
import '../../widgets/light_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    final stats = await _firebaseService.getStatistics();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques 24h',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_stats != null) ...[
              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Temp. Moyenne',
                      '${_stats!['avgTemp'].toStringAsFixed(1)}°C',
                      Icons.thermostat,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Lumière Moy.',
                      '${_stats!['avgLight']}%',
                      Icons.wb_sunny,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Min',
                      '${_stats!['minTemp'].toStringAsFixed(1)}°C',
                      Icons.arrow_downward,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Max',
                      '${_stats!['maxTemp'].toStringAsFixed(1)}°C',
                      Icons.arrow_upward,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Nombre de mesures',
                '${_stats!['count']}',
                Icons.data_usage,
                Colors.purple,
              ),
              const SizedBox(height: 24),

              // Graphiques
              Text(
                'Graphiques',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              StreamBuilder<List<SensorData>>(
                stream: _firebaseService.getHistory24h(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.show_chart,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune donnée historique',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Les données apparaîtront ici après quelques minutes',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!.reversed.toList();

                  return Column(
                    children: [
                      TemperatureChart(data: data),
                      const SizedBox(height: 12),
                      LightChart(data: data),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}