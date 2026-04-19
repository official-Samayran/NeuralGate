import 'package:flutter/material.dart';

class NeuralGraph extends StatelessWidget {
  final List<double> points;
  final double threshold;
  final double graphMax;

  const NeuralGraph({
    super.key, 
    required this.points, 
    required this.threshold, 
    required this.graphMax
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GraphPainter(points, threshold, graphMax),
        size: Size.infinite,
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<double> points;
  final double threshold;
  final double graphMax;

  _GraphPainter(this.points, this.threshold, this.graphMax);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double spacing = size.width / 149;
    
    double getY(double val) {
      double pos = size.height - (val / graphMax * size.height);
      return pos.clamp(0, size.height);
    }

    // 1. Draw Background Grid (Subtle)
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 0.5;
    for (int i = 1; i < 5; i++) {
      double y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw Threshold Line
    final tPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    double ty = getY(threshold);
    
    // Dashed threshold line
    for (double i = 0; i < size.width; i += 10) {
      canvas.drawLine(Offset(i, ty), Offset(i + 5, ty), tPaint);
    }

    // 3. Draw Signal Path
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      double x = i * spacing;
      double y = getY(points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Glowing Neon Effect
    final glowPaint = Paint()
      ..color = const Color(0xFF007AFF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    final linePaint = Paint()
      ..color = const Color(0xFF007AFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_GraphPainter oldDelegate) => true; 
}