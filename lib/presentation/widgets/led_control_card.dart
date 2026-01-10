import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/led_provider.dart';
import '../../core/constants/colors.dart';

class LedControlCard extends StatelessWidget {
  const LedControlCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LedProvider>(
      builder: (context, provider, child) {
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
                        color: provider.isOn
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
                              color: provider.isOn ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              boxShadow: provider.isOn
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
                            provider.isOn ? 'ON' : 'OFF',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: provider.isOn ? Colors.green : Colors.grey,
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
                        onPressed: provider.isLoading
                            ? null
                            : () => provider.turnOn(),
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
                        onPressed: provider.isLoading
                            ? null
                            : () => provider.turnOff(),
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
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.toggle(),
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