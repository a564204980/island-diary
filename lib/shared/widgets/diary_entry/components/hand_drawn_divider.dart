import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 手绘风格直线绘制器（用于分割线）
class HandDrawnLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  HandDrawnLinePainter({required this.color, this.strokeWidth = 1.2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double w = size.width;
    final double h = size.height / 2;

    path.moveTo(0, h);

    // 使用随机感波动的贝塞尔曲线绘制线条
    final random = math.Random(42); // 固定种子保证线条稳定
    double lastX = 0;
    double lastY = h;

    for (double i = 20; i <= w; i += 40) {
      final double controlX = lastX + 20;
      final double controlY = h + (random.nextDouble() * 2 - 1);
      final double endX = i;
      final double endY = h + (random.nextDouble() * 1.5 - 0.75);

      path.quadraticBezierTo(controlX, controlY, endX, endY);
      lastX = endX;
      lastY = endY;
    }
    path.lineTo(w, lastY);

    canvas.drawPath(path, paint);

    // 叠加一层极细的复笔增加手绘真实感
    canvas.drawPath(
      path,
      paint
        ..strokeWidth = strokeWidth * 0.3
        ..color = color.withOpacity(0.2),
    );
  }

  @override
  bool shouldRepaint(covariant HandDrawnLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
