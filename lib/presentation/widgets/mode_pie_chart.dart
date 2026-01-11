import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/colors.dart';

class ModePieChart extends StatefulWidget {
  final Map<String, double> data;

  const ModePieChart({super.key, required this.data});

  @override
  State<ModePieChart> createState() => _ModePieChartState();
}

class _ModePieChartState extends State<ModePieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final manuelPercent = widget.data['MANUEL'] ?? 0;
    final autoTempPercent = widget.data['AUTO-TEMP'] ?? 0;
    final autoLightPercent = widget.data['AUTO-LIGHT'] ?? 0;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: [
                PieChartSectionData(
                  color: Colors.blue,
                  value: manuelPercent,
                  title: '${manuelPercent.toStringAsFixed(0)}%',
                  radius: touchedIndex == 0 ? 65 : 55,
                  titleStyle: TextStyle(
                    fontSize: touchedIndex == 0 ? 18 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: autoTempPercent,
                  title: '${autoTempPercent.toStringAsFixed(0)}%',
                  radius: touchedIndex == 1 ? 65 : 55,
                  titleStyle: TextStyle(
                    fontSize: touchedIndex == 1 ? 18 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: autoLightPercent,
                  title: '${autoLightPercent.toStringAsFixed(0)}%',
                  radius: touchedIndex == 2 ? 65 : 55,
                  titleStyle: TextStyle(
                    fontSize: touchedIndex == 2 ? 18 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('MANUEL', Colors.blue, manuelPercent),
            _buildLegendItem('AUTO-TEMP', Colors.red, autoTempPercent),
            _buildLegendItem('AUTO-LIGHT', Colors.orange, autoLightPercent),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, double percent) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}