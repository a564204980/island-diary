import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 自定义绘制带突起的背景
class MoodPickerBackgroundPainter extends CustomPainter {
  final bool isSolid;

  MoodPickerBackgroundPainter({this.isSolid = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = isSolid ? Colors.white : Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // ======= 连续路径重塑：确保背景完整且无缝 =======
    final double r = radius;
    final double outerR = r + 14;

    final path = Path();

    // ======= 侧边统一大突起：整合强度条与标签按钮背景 =======
    final shiftedCenter = Offset(center.dx + 15, center.dy);
    const double startAngle = -60 * math.pi / 180;

    path.moveTo(
      center.dx + r * math.cos(startAngle),
      center.dy + r * math.sin(startAngle),
    );

    // 1. 爬坡
    path.cubicTo(
      center.dx + (r + 1) * math.cos(-57 * math.pi / 180),
      center.dy + (r + 1) * math.sin(-57 * math.pi / 180),
      shiftedCenter.dx + (outerR - 1) * math.cos(-53 * math.pi / 180),
      shiftedCenter.dy + (outerR - 1) * math.sin(-53 * math.pi / 180),
      shiftedCenter.dx + outerR * math.cos(-50 * math.pi / 180),
      shiftedCenter.dy + outerR * math.sin(-50 * math.pi / 180),
    );

    // 2. 突起顶部大圆弧
    path.arcTo(
      Rect.fromCircle(center: shiftedCenter, radius: outerR),
      -50 * math.pi / 180,
      (50 + 65) * math.pi / 180,
      false,
    );

    // 3. 下坡
    path.cubicTo(
      shiftedCenter.dx + (outerR - 1) * math.cos(67 * math.pi / 180),
      shiftedCenter.dy + (outerR - 1) * math.sin(67 * math.pi / 180),
      center.dx + (r + 1) * math.cos(69 * math.pi / 180),
      center.dy + (r + 1) * math.sin(69 * math.pi / 180),
      center.dx + r * math.cos(72 * math.pi / 180),
      center.dy + r * math.sin(72 * math.pi / 180),
    );

    // 4. 完成剩余的大圆弧
    path.arcTo(
      Rect.fromCircle(center: center, radius: r),
      72 * math.pi / 180,
      (360 - 72 - 60) * math.pi / 180,
      false,
    );

    path.close();
    final combinedPath = path;

    // ======= 纯粹边缘外发光实现 =======
    final ambientGlowPaint = Paint()
      ..color = const Color.fromRGBO(213, 213, 213, 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12.0);
    canvas.drawPath(combinedPath, ambientGlowPaint);

    final goldenGlowPaint = Paint()
      ..color = const Color.fromRGBO(244, 214, 115, 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6.0);
    canvas.drawPath(combinedPath, goldenGlowPaint);

    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant MoodPickerBackgroundPainter oldDelegate) {
    return oldDelegate.isSolid != isSolid;
  }
}
