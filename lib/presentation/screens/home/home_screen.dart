import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/sensor_provider.dart';
import '../../../providers/led_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/temperature_card.dart';
import '../../widgets/light_card.dart';
import '../../widgets/led_control_card.dart';
import '../history/history_screen.dart';
import '../sensors/sensors_screen.dart';
import '../led_control/led_control_screen.dart';
import '../settings/settings_screen.dart';
import '../statistics/statistics_screen.dart';
import '../../../core/utils/page_transitions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();

    // Animation FAB
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );
    _fabController.forward();

    // Démarrer le polling des données
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SensorProvider>().startPolling();
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    context.read<SensorProvider>().stopPolling();
    super.dispose();
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
        elevation: 0,
        actions: [
          // Bouton Refresh avec animation
          ScaleTransition(
            scale: _fabAnimation,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<SensorProvider>().fetchSensorData();
                _fabController.reset();
                _fabController.forward();
              },
              tooltip: 'Rafraîchir',
            ),
          ),

          // Indicateur Firebase
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              if (settings.firebaseEnabled) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.cloud_done,
                            size: 16,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // ✅ NOUVEAU : Bouton History
          // ✅ NOUVEAU : Bouton History
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                SlideRightRoute(page: const HistoryScreen()),
              );
            },
            tooltip: 'Historique',
          ),

          // Bouton Settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                  const SettingsScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                ),
              );
            },
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        animationDuration: const Duration(milliseconds: 400),
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
      floatingActionButton: _currentIndex == 0
          ? ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              ScaleRoute(page: const SensorsScreen()),
            );
          },
          icon: const Icon(Icons.sensors),
          label: const Text('Détails'),
          tooltip: 'Voir détails capteurs',
        ),
      )
          : null,
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
                  // Status Card amélioré
                  _buildEnhancedStatusCard(context),
                  const SizedBox(height: 20),

                  // Mode actuel
                  _buildModeCard(context),
                  const SizedBox(height: 20),

                  // Sensors Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Capteurs',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            FadeRoute(page: const SensorsScreen()),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Détails'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Temperature Card avec animation
                  AnimatedCard(
                    delay: 0,
                    child: const TemperatureCard(),
                  ),
                  const SizedBox(height: 12),

// Light Card avec animation
                  AnimatedCard(
                    delay: 100,
                    child: const LightCard(),
                  ),

                  // LED Control
                  Text(
                    'Contrôle LED',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const LedControlCard(),

                  const SizedBox(height: 20),

                  // Quick stats
                  _buildQuickStats(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatusCard(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, child) {
        final isConnected = provider.currentData != null;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Card(
                elevation: isConnected ? 4 : 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: isConnected
                        ? LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.1),
                        Colors.green.withOpacity(0.05),
                      ],
                    )
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Animated dot
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween(begin: 0.8, end: 1.2),
                          curve: Curves.easeInOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: isConnected ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: isConnected
                                          ? Colors.green.withOpacity(0.6)
                                          : Colors.red.withOpacity(0.6),
                                      blurRadius: 12,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          onEnd: () {
                            // Repeat animation
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConnected ? 'Système en ligne' : 'Système hors ligne',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isConnected
                                    ? 'ESP32 connecté et opérationnel'
                                    : 'Vérifiez la connexion réseau',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (provider.isLoading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        else if (isConnected)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeCard(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final mode = settings.currentMode;

        IconData icon;
        Color color;
        String description;

        switch (mode) {
          case 'AUTO-TEMP':
            icon = Icons.thermostat;
            color = Colors.red;
            description = 'Contrôle automatique par température';
            break;
          case 'AUTO-LIGHT':
            icon = Icons.wb_sunny;
            color = Colors.orange;
            description = 'Contrôle automatique par lumière';
            break;
          default:
            icon = Icons.touch_app;
            color = Colors.blue;
            description = 'Contrôle manuel de la LED';
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Mode actuel : ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            mode,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  tooltip: 'Changer le mode',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        final data = provider.currentData;

        if (data == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques rapides',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Lectures',
                    '${provider.currentData != null ? "Active" : "0"}',
                    Icons.update,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer<LedProvider>(
                    builder: (context, led, _) {
                      return _buildStatCard(
                        'LED',
                        led.isOn ? 'ON' : 'OFF',
                        Icons.lightbulb,
                        led.isOn ? Colors.green : Colors.grey,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
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
        ),
      ),
    );
  }
}