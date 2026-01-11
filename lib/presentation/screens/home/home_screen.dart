import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/sensor_provider.dart';
import '../../../providers/led_provider.dart';
import '../../widgets/temperature_card.dart';
import '../../widgets/light_card.dart';
import '../../widgets/led_control_card.dart';
import '../sensors/sensors_screen.dart';
import '../led_control/led_control_screen.dart';
import '../settings/settings_screen.dart';
import '../statistics/statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Démarrer le polling des données
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SensorProvider>().startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardTab(),
      const LedControlScreen(),
      const StatisticsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TTGO IoT Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SensorProvider>().fetchSensorData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),

        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Control',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

// Dashboard Tab
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<SensorProvider>().fetchSensorData(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  _buildStatusCard(context),
                  const SizedBox(height: 20),

                  // Sensors Section
                  Text(
                    'Capteurs',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Temperature Card
                  const TemperatureCard(),
                  const SizedBox(height: 12),

                  // Light Card
                  const LightCard(),
                  const SizedBox(height: 20),

                  // LED Control
                  Text(
                    'Contrôle LED',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const LedControlCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, child) {
        final isConnected = provider.currentData != null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isConnected
                            ? Colors.green.withOpacity(0.5)
                            : Colors.red.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? 'Connecté' : 'Déconnecté',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isConnected
                            ? 'ESP32 en ligne'
                            : 'Vérifiez la connexion',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (provider.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}