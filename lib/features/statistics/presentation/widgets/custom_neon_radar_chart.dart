import 'dart:math';
import 'package:flutter/material.dart';

class NeonRadarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final List<String>? iconPaths;
  final List<Color>? glowColors;
  final double maxValue;
  final bool isNight;

  const NeonRadarChart({
    super.key,
    required this.values,
    required this.labels,
    this.iconPaths,
    this.glowColors,
    this.maxValue = 1.0,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final double size = min(width, height);
        // Leave padding for the labels around the chart
        final double padding = 36.0; 
        final double radius = (size / 2) - padding;
        final Offset center = Offset(width / 2, height / 2);

        List<Widget> labelWidgets = [];
        int n = values.length;

        for (int i = 0; i < n; i++) {
          double angle = -pi / 2 + (2 * pi / n) * i;
          // Place label slightly outside the max radius
          // Label container needs to be centered based on text size, so we offset carefully.
          double labelR = radius + 22.0; 
          double lx = center.dx + labelR * cos(angle);
          double ly = center.dy + labelR * sin(angle);

          // Construct the label block
          Widget labelBlock = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconPaths != null && iconPaths![i].isNotEmpty)
                Image.asset(iconPaths![i], width: 18, height: 18),
              const SizedBox(height: 2),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          );

          labelWidgets.add(
            Positioned(
              left: lx - 30, // assuming max width of label block is ~60
              top: ly - 20,  // assuming height is ~40
              width: 60,
              child: Center(child: labelBlock),
            ),
          );
        }

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _NeonRadarPainter(
                  values: values,
                  maxValue: maxValue,
                  isNight: isNight,
                  glowColors: glowColors,
                  radius: radius,
                  center: center,
                ),
              ),
              ...labelWidgets,
            ],
          ),
        );
      },
    );
  }
}

class _NeonRadarPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final bool isNight;
  final List<Color>? glowColors;
  final double radius;
  final Offset center;

  _NeonRadarPainter({
    required this.values,
    required this.maxValue,
    required this.isNight,
    this.glowColors,
    required this.radius,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int n = values.length;
    if (n < 3) return;

    // 1. Draw Web Grids (Concentric Circles or Polygons)
    final gridPaint = Paint()
      ..color = isNight ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    int gridLevels = 3;
    for (int level = 1; level <= gridLevels; level++) {
      double r = radius * (level / gridLevels);
      // Let's use concentric circles to make it feel futuristic, instead of sharp polygons.
      canvas.drawCircle(center, r, gridPaint);
    }

    // 2. Draw Spokes (from center to edges)
    for (int i = 0; i < n; i++) {
      double angle = -pi / 2 + (2 * pi / n) * i;
      double px = center.dx + radius * cos(angle);
      double py = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(px, py), gridPaint);
    }

    // 3. Calculate data points path
    Path dataPath = Path();
    List<Offset> points = [];

    double effectiveMax = maxValue <= 0 ? 1 : maxValue;

    for (int i = 0; i < n; i++) {
      double angle = -pi / 2 + (2 * pi / n) * i;
      double valueRatio = (values[i] / effectiveMax).clamp(0.0, 1.0);
      double r = radius * valueRatio;
      
      // Ensure there's a tiny minimal visible radius even for 0 values to show the shape loosely
      if (r < 5.0) r = 5.0;

      double px = center.dx + r * cos(angle);
      double py = center.dy + r * sin(angle);
      points.add(Offset(px, py));

      if (i == 0) {
        dataPath.moveTo(px, py);
      } else {
        dataPath.lineTo(px, py);
      }
    }
    dataPath.close();

    // 4. Fill Polygon with Neon Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          isNight ? const Color(0xFFB39DDB).withOpacity(0.6) : const Color(0xFF9575CD).withOpacity(0.5),
          isNight ? const Color(0xFF80D8FF).withOpacity(0.4) : const Color(0xFF40C4FF).withOpacity(0.3),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
      
    // 5. Add Core Shadow / Glow under the polygon
    canvas.drawShadow(dataPath, const Color(0xFF673AB7).withOpacity(isNight ? 0.3 : 0.45), 8.0, false);
    canvas.drawPath(dataPath, fillPaint);

    // 6. Draw Polygon Border
    final borderPaint = Paint()
      ..color = isNight ? const Color(0xFFD1C4E9) : const Color(0xFF673AB7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isNight ? 2.5 : 3.2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dataPath, borderPaint);

    // 7. Draw Vertex Dots
    for (int i = 0; i < n; i++) {
      Color dotColor = glowColors != null ? glowColors![i] : borderPaint.color;
      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;
      final dotBorderPaint = Paint()
        ..color = isNight ? const Color(0xFF2C2C2C) : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(points[i], 4.5, dotPaint);
      canvas.drawCircle(points[i], 4.5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeonRadarPainter oldDelegate) {
    return oldDelegate.values != values || 
           oldDelegate.maxValue != maxValue ||
           oldDelegate.isNight != isNight;
  }
}
