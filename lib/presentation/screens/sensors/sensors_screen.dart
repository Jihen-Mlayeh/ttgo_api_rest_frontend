import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/sensor_provider.dart';
import '../../../data/services/firebase_service.dart';
import '../../../data/models/sensor_data.dart';
import '../../widgets/thermometer_widget.dart';
import '../../widgets/light_gauge_widget.dart';
import '../../widgets/temperature_chart.dart';
import '../../widgets/light_chart.dart';
import '../../widgets/json_viewer_dialog.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _firebaseService.getStatistics();
    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails Capteurs'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: Consumer<SensorProvider>(
          builder: (context, provider, child) {
            final data = provider.currentData;

            if (data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Chargement des données...'),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<SensorProvider>().fetchSensorData();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                    const SizedBox(height: 12),
                    if (provider.error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Erreur: ${provider.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section Température
                _buildTemperatureSection(data),
                const SizedBox(height: 24),

                // Section Lumière
                _buildLightSection(data),
                const SizedBox(height: 24),

                // Graphiques historiques
                Text(
                  'Historique 24h',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                StreamBuilder<List<SensorData>>(
                  stream: _firebaseService.getHistory24h(),
                  builder: (context, snapshot) {
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
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final historyData = snapshot.data!.reversed.toList();

                    return Column(
                      children: [
                        TemperatureChart(data: historyData),
                        const SizedBox(height: 12),
                        LightChart(data: historyData),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTemperatureSection(SensorData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.thermostat,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Température',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.code),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => JsonViewerDialog(
                        title: 'Données Température',
                        data: {
                          'temperature': data.temperature,
                          'timestamp': data.timestamp.toIso8601String(),
                          'unit': 'celsius',
                        },
                      ),
                    );
                  },
                  tooltip: 'Voir JSON',
                ),
              ],
            ),
            const SizedBox(height: 24),

            Center(
              child: ThermometerWidget(
                temperature: data.temperature,
              ),
            ),

            const SizedBox(height: 24),

            if (_stats != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Min 24h',
                    '${_stats!['minTemp'].toStringAsFixed(1)}°C',
                    Icons.arrow_downward,
                    Colors.blue,
                  ),
                  _buildStatItem(
                    'Moyenne',
                    '${_stats!['avgTemp'].toStringAsFixed(1)}°C',
                    Icons.show_chart,
                    Colors.orange,
                  ),
                  _buildStatItem(
                    'Max 24h',
                    '${_stats!['maxTemp'].toStringAsFixed(1)}°C',
                    Icons.arrow_upward,
                    Colors.red,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLightSection(SensorData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.wb_sunny,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Lumière',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.code),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => JsonViewerDialog(
                        title: 'Données Lumière',
                        data: {
                          'light_percent': data.lightPercent,
                          'light_raw': data.lightRaw,
                          'timestamp': data.timestamp.toIso8601String(),
                        },
                      ),
                    );
                  },
                  tooltip: 'Voir JSON',
                ),
              ],
            ),
            const SizedBox(height: 24),

            Center(
              child: LightGaugeWidget(
                lightPercent: data.lightPercent,
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Valeur brute',
                  '${data.lightRaw}',
                  Icons.numbers,
                  Colors.purple,
                ),
                _buildStatItem(
                  'Pourcentage',
                  '${data.lightPercent}%',
                  Icons.percent,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}