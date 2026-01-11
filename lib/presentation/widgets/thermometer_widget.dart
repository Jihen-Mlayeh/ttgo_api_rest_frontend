import 'package:flutter/material.dart';
import 'dart:math' as math;

class ThermometerWidget extends StatelessWidget {
  final double temperature;
  final double minTemp;
  final double maxTemp;

  const ThermometerWidget({
    super.key,
    required this.temperature,
    this.minTemp = 0,
    this.maxTemp = 50,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = ((temperature - minTemp) / (maxTemp - minTemp)).clamp(0.0, 1.0);
    final color = _getTemperatureColor(temperature);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Thermomètre
        SizedBox(
          width: 80,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Tube du thermomètre
              Positioned(
                bottom: 20,
                child: Container(
                  width: 30,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                ),
              ),

              // Mercure animé
              Positioned(
                bottom: 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percentage),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Container(
                      width: 26,
                      height: 196 * value,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            color,
                            color.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                    );
                  },
                ),
              ),

              // Bulbe
              Positioned(
                bottom: 0,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),

              // Graduations
              ..._buildGraduations(),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Valeur
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: temperature),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Text(
              '${value.toStringAsFixed(1)}°C',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildGraduations() {
    final graduations = <Widget>[];
    for (int i = 0; i <= 5; i++) {
      final temp = minTemp + (maxTemp - minTemp) * (i / 5);
      final position = 220.0 - (200.0 * (i / 5));

      graduations.add(
        Positioned(
          bottom: position - 10,
          right: 45,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 2,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 4),
              Text(
                '${temp.toInt()}°',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return graduations;
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 15) return Colors.blue;
    if (temp < 25) return Colors.green;
    if (temp < 30) return Colors.orange;
    if (temp < 35) return Colors.deepOrange;
    return Colors.red;
  }
}