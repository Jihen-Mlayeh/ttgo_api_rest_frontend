import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/stats_provider.dart';
import '../../../data/services/firebase_service.dart';
import '../../../data/models/sensor_data.dart';
import '../../widgets/temperature_chart.dart';
import '../../widgets/light_chart.dart';
import '../../widgets/mode_pie_chart.dart';
import '../../widgets/led_bar_chart.dart';
import '../../widgets/animated_card.dart';

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
    // ✅ NOUVEAU : Charger les stats du provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().refreshStats();
    });
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
      onRefresh: () async {
        await _loadStatistics();
        await context.read<StatsProvider>().refreshStats();
      },
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
              AnimatedCard(
                delay: 0,
                child: Row(
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
              ),
              const SizedBox(height: 12),

              AnimatedCard(
                delay: 100,
                child: Row(
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
              ),
              const SizedBox(height: 12),

              AnimatedCard(
                delay: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Mesures',
                        '${_stats!['count']}',
                        Icons.data_usage,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer<StatsProvider>(
                        builder: (context, stats, _) {
                          return _buildStatCard(
                            'Uptime',
                            stats.uptimeString,
                            Icons.timer,
                            Colors.green,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Mode Distribution
              Text(
                'Répartition des modes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              AnimatedCard(
                delay: 300,
                child: Consumer<StatsProvider>(
                  builder: (context, stats, _) {
                    // ✅ VÉRIFIE SI LES DONNÉES SONT VIDES
                    if (stats.modeData.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.pie_chart,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune donnée disponible',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ModePieChart(data: stats.modeData),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // LED Usage
              Text(
                'Utilisation LED (24h)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              AnimatedCard(
                delay: 400,
                child: Consumer<StatsProvider>(
                  builder: (context, stats, _) {
                    // ✅ VÉRIFIE SI LES DONNÉES SONT VIDES
                    if (stats.ledData.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.bar_chart,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune donnée disponible',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'LED Active par période',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Moy: ${stats.avgLedOnTime.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            LedBarChart(data: stats.ledData),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Additional Stats
              Text(
                'Statistiques avancées',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              AnimatedCard(
                delay: 500,
                child: Consumer<StatsProvider>(
                  builder: (context, stats, _) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildStatRow(
                              'Changements de mode',
                              '${stats.totalModeChanges}',
                              Icons.swap_horiz,
                              Colors.purple,
                            ),
                            const Divider(height: 24),
                            _buildStatRow(
                              'Temps LED allumée (moy)',
                              '${stats.avgLedOnTime.toStringAsFixed(1)}%',
                              Icons.lightbulb,
                              Colors.green,
                            ),
                            const Divider(height: 24),
                            _buildStatRow(
                              'Uptime système',
                              stats.uptimeString,
                              Icons.schedule,
                              Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Graphiques historiques
              Text(
                'Graphiques historiques',
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
                              Text(
                                'Les données seront disponibles après quelques minutes',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
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
                      AnimatedCard(
                        delay: 600,
                        child: TemperatureChart(data: data),
                      ),
                      const SizedBox(height: 12),
                      AnimatedCard(
                        delay: 700,
                        child: LightChart(data: data),
                      ),
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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

  Widget _buildStatRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}