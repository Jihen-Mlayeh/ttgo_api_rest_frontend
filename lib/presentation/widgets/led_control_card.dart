import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/led_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../core/constants/colors.dart';

class LedControlCard extends StatelessWidget {
  const LedControlCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LedProvider, SensorProvider>(
      builder: (context, ledProvider, sensorProvider, child) {
        // ✅ Lire l'état RÉEL depuis l'ESP32
        final isOn = sensorProvider.currentData?.ledState ?? ledProvider.isOn;
        final isLoading = ledProvider.isLoading;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LED',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOn
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOn ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              boxShadow: isOn
                                  ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOn ? 'ON' : 'OFF',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOn ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => ledProvider.turnOn(),
                        icon: const Icon(Icons.power_settings_new),
                        label: const Text('ON'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => ledProvider.turnOff(),
                        icon: const Icon(Icons.power_settings_new),
                        label: const Text('OFF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => ledProvider.toggle(),
                    icon: const Icon(Icons.sync),
                    label: const Text('Toggle'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}