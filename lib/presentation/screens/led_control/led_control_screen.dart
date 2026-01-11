import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/led_provider.dart';
import '../../../providers/sensor_provider.dart';
import '../../../core/constants/colors.dart';

class LedControlScreen extends StatelessWidget {
  const LedControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LedProvider, SensorProvider>(
      builder: (context, ledProvider, sensorProvider, child) {
        // ✅ Lire l'état RÉEL depuis l'ESP32
        final isOn = sensorProvider.currentData?.ledState ?? ledProvider.isOn;
        final isLoading = ledProvider.isLoading;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // LED visuelle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isOn
                              ? Colors.yellow
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                          boxShadow: isOn
                              ? [
                            BoxShadow(
                              color: Colors.yellow.withOpacity(0.6),
                              blurRadius: 40,
                              spreadRadius: 20,
                            ),
                          ]
                              : null,
                        ),
                        child: Icon(
                          Icons.lightbulb,
                          size: 60,
                          color: isOn ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isOn ? 'LED Allumée' : 'LED Éteinte',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Contrôles
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contrôles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildControlButton(
                        context,
                        'Allumer',
                        Icons.power_settings_new,
                        Colors.green,
                            () => ledProvider.turnOn(),
                        isLoading,
                      ),
                      const SizedBox(height: 12),
                      _buildControlButton(
                        context,
                        'Éteindre',
                        Icons.power_settings_new,
                        Colors.red,
                            () => ledProvider.turnOff(),
                        isLoading,
                      ),
                      const SizedBox(height: 12),
                      _buildControlButton(
                        context,
                        'Basculer',
                        Icons.sync,
                        AppColors.primary,
                            () => ledProvider.toggle(),
                        isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      bool isLoading,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}