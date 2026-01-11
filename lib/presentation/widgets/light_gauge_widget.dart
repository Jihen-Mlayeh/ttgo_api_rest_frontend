import 'package:flutter/material.dart';
import 'dart:math' as math;

class LightGaugeWidget extends StatelessWidget {
  final int lightPercent;

  const LightGaugeWidget({
    super.key,
    required this.lightPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 250,
          height: 150,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: lightPercent / 100),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                painter: _GaugePainter(
                  value: value,
                  color: _getLightColor(lightPercent),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getLightLabel(lightPercent),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Icônes indicateurs
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLightIcon('🌑', 'Sombre', lightPercent < 20),
            const SizedBox(width: 16),
            _buildLightIcon('☁️', 'Nuageux', lightPercent >= 20 && lightPercent < 40),
            const SizedBox(width: 16),
            _buildLightIcon('⛅', 'Couvert', lightPercent >= 40 && lightPercent < 60),
            const SizedBox(width: 16),
            _buildLightIcon('🌤️', 'Clair', lightPercent >= 60 && lightPercent < 80),
            const SizedBox(width: 16),
            _buildLightIcon('☀️', 'Ensoleillé', lightPercent >= 80),
          ],
        ),
      ],
    );
  }

  Widget _buildLightIcon(String emoji, String label, bool isActive) {
    return Opacity(
      opacity: isActive ? 1.0 : 0.3,
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: isActive ? 32 : 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLightColor(int percent) {
    if (percent < 25) return Colors.indigo;
    if (percent < 50) return Colors.blue;
    if (percent < 75) return Colors.orange;
    return Colors.amber;
  }

  String _getLightLabel(int percent) {
    if (percent < 20) return 'Très sombre';
    if (percent < 40) return 'Sombre';
    if (percent < 60) return 'Moyen';
    if (percent < 80) return 'Lumineux';
    return 'Très lumineux';
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;

  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Foreground arc
    final fgPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.5), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * value,
      false,
      fgPaint,
    );

    // Graduations
    for (int i = 0; i <= 10; i++) {
      final angle = math.pi + (math.pi * i / 10);
      final x1 = center.dx + (radius - 10) * math.cos(angle);
      final y1 = center.dy + (radius - 10) * math.sin(angle);
      final x2 = center.dx + (radius + 10) * math.cos(angle);
      final y2 = center.dy + (radius + 10) * math.sin(angle);

      final paint = Paint()
        ..color = Colors.grey[400]!
        ..strokeWidth = 2;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}