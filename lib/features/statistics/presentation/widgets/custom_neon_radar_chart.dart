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
        final double padding = 42.0; 
        final double radius = (size / 2) - padding;
        final Offset center = Offset(width / 2, height / 2);

        List<Widget> labelWidgets = [];
        int n = values.length;

        for (int i = 0; i < n; i++) {
          double angle = -pi / 2 + (2 * pi / n) * i;
          double labelR = radius + 28.0; 
          double lx = center.dx + labelR * cos(angle);
          double ly = center.dy + labelR * sin(angle);

          Widget labelBlock = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconPaths != null && i < iconPaths!.length && iconPaths![i].isNotEmpty)
                Image.asset(iconPaths![i], width: 20, height: 20),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white70 : Colors.black87,
                  fontFamily: 'LXGWWenKai',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          labelWidgets.add(
            Positioned(
              left: lx - 30,
              top: ly - 22,
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
                painter: _BloomRadarPainter(
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

class _BloomRadarPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final bool isNight;
  final List<Color>? glowColors;
  final double radius;
  final Offset center;

  _BloomRadarPainter({
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

    final gridPaint = Paint()
      ..color = isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. 绘制背景网格（柔动的同心圆）
    int gridLevels = 4;
    for (int level = 1; level <= gridLevels; level++) {
      double r = radius * (level / gridLevels);
      canvas.drawCircle(center, r, gridPaint);
    }

    // 2. 绘制轴线（带微弱光晕）
    for (int i = 0; i < n; i++) {
      double angle = -pi / 2 + (2 * pi / n) * i;
      double px = center.dx + radius * cos(angle);
      double py = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(px, py), gridPaint);
    }

    // 3. 计算“花瓣”路径 - 使用平滑的贝塞尔曲线代替直线
    Path bloomPath = Path();
    List<Offset> points = [];
    double effectiveMax = maxValue <= 0 ? 1 : maxValue;

    for (int i = 0; i < n; i++) {
      double angle = -pi / 2 + (2 * pi / n) * i;
      double valueRatio = (values[i] / effectiveMax).clamp(0.1, 1.0);
      double r = radius * valueRatio;
      double px = center.dx + r * cos(angle);
      double py = center.dy + r * sin(angle);
      points.add(Offset(px, py));
    }

    // 使用 Catmull-Rom 插值或简单的贝塞尔曲线实现“花瓣”绽放效果
    bloomPath.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < n; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % n];
      
      // 控制点设在两个顶点的中点，但向外稍微偏移以产生弧度
      final midX = (p1.dx + p2.dx) / 2;
      final midY = (p1.dy + p2.dy) / 2;
      
      // 向外偏移，数据越大，弧度越圆润
      final offsetFactor = 1.15; 
      final petalX = center.dx + (midX - center.dx) * offsetFactor;
      final petalY = center.dy + (midY - center.dy) * offsetFactor;
      
      bloomPath.quadraticBezierTo(petalX, petalY, p2.dx, p2.dy);
    }
    bloomPath.close();

    // 4. 填充渐变色（花瓣质感）
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (glowColors != null && glowColors!.isNotEmpty ? glowColors![0] : const Color(0xFF91EAE4)).withOpacity(0.3),
          (glowColors != null && glowColors!.length > 1 ? glowColors![1] : const Color(0xFF7F7FD5)).withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.2))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(bloomPath, fillPaint);

    // 5. 绘制平滑边缘
    final borderPaint = Paint()
      ..shader = SweepGradient(
        colors: glowColors ?? [const Color(0xFFD1C4E9), const Color(0xFFB39DDB)],
        center: Alignment.center,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    
    // 柔化阴影
    // 移除原有阴影，避免在透明背景上产生“第二层背景”的感官
    // canvas.drawShadow(bloomPath, (glowColors != null ? glowColors![0] : Colors.purple).withOpacity(0.3), 10, true);
    canvas.drawPath(bloomPath, borderPaint);

    // 6. 绘制顶点（发光的露珠）
    for (int i = 0; i < n; i++) {
      Color dotColor = (glowColors != null && i < glowColors!.length) ? glowColors![i] : Colors.white;
      
      // 顶点光晕
      final glowPaint = Paint()
        ..color = dotColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(points[i], 8, glowPaint);
      
      // 核心
      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(points[i], 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BloomRadarPainter oldDelegate) {
    return oldDelegate.values != values || 
           oldDelegate.maxValue != maxValue ||
           oldDelegate.isNight != isNight;
  }
}
