import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ModePieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const ModePieChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Aucune donnée disponible'),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: data.map((item) {
                final mode = item['mode'] as String;
                final value = (item['value'] as num).toDouble();
                final color = item['color'] as Color;

                return PieChartSectionData(
                  value: value,
                  title: '$value%',
                  color: color,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 60,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: data.map((item) {
            final mode = item['mode'] as String;
            final value = (item['value'] as num).toDouble();
            final color = item['color'] as Color;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  mode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$value%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}