import 'package:flutter/material.dart';
import 'dart:math';

class SpeedMeter extends StatelessWidget {
  final double currentDelay;
  final double maxDelay;
  final double minDelay;

  const SpeedMeter({
    super.key,
    required this.currentDelay,
    this.maxDelay = 1000.0,
    this.minDelay = 0.0,
  });

  double _normalized() {
    final span = maxDelay - minDelay;
    if (span <= 0) return 0.5;
    return ((currentDelay - minDelay) / span).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _normalized();
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    final maxSize = min(screenWidth, screenHeight) * 0.4;
    final size = maxSize.clamp(120.0, 200.0);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SpeedMeterPainter(
          normalized: normalized,
          currentDelay: currentDelay,
          minDelay: minDelay,
          maxDelay: maxDelay,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Speed',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${currentDelay.round()} ms',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedMeterPainter extends CustomPainter {
  final double normalized;
  final double currentDelay;
  final double minDelay;
  final double maxDelay;

  _SpeedMeterPainter({
    required this.normalized,
    required this.currentDelay,
    required this.minDelay,
    required this.maxDelay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = size.width * 0.38;
    final startAngle = 210 * pi / 180;
    final sweepAngle = 120 * pi / 180;

    final basePaint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.orange, Colors.green],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      basePaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * (1 - normalized),
      false,
      fillPaint,
    );

    final tickPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 2;

    for (int i = 0; i <= 6; i++) {
      final t = i / 6;
      final angle = startAngle + sweepAngle * (1 - t);
      final inner = Offset(
        center.dx + (radius - 10) * cos(angle),
        center.dy + (radius - 10) * sin(angle),
      );
      final outer = Offset(
        center.dx + (radius + 6) * cos(angle),
        center.dy + (radius + 6) * sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    final needleAngle = startAngle + sweepAngle * (1 - normalized);
    final needleLength = radius - 6;
    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
