import 'package:flutter/material.dart';

// ==========================================
// 自定义装饰与插画组件
// ==========================================

class CloudIllustrationWidget extends StatelessWidget {
  final bool isNight;
  final Color primaryColor;
  const CloudIllustrationWidget({super.key, required this.isNight, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 80,
      child: CustomPaint(
        painter: CloudIllustrationPainter(isNight: isNight, primaryColor: primaryColor),
      ),
    );
  }
}

class CloudIllustrationPainter extends CustomPainter {
  final bool isNight;
  final Color primaryColor;
  CloudIllustrationPainter({required this.isNight, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制虚线轨迹
    final dashPaint = Paint()
      ..color = isNight ? Colors.white.withValues(alpha: 0.08) : primaryColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    
    final path1 = Path();
    path1.addArc(Rect.fromLTWH(-20, 15, 100, 80), 3.14 * 0.8, 3.14 * 0.8);
    _drawDashedPath(canvas, path1, dashPaint, 4, 3);

    final path2 = Path();
    path2.addArc(Rect.fromLTWH(20, -5, 80, 70), 3.14 * 1.1, 3.14 * 0.7);
    _drawDashedPath(canvas, path2, dashPaint, 4, 3);

    // 2. 绘制云朵
    final cloudGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isNight
          ? [const Color(0xFF374151), const Color(0xFF1F2937)]
          : [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)],
    );

    final cloudPaint = Paint()
      ..shader = cloudGrad.createShader(Rect.fromLTWH(size.width * 0.2, size.height * 0.2, size.width * 0.7, size.height * 0.55))
      ..style = PaintingStyle.fill;

    final cloudPath = Path();
    // 底部圆角矩形
    cloudPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.45, size.width * 0.55, size.height * 0.25),
      const Radius.circular(15),
    ));
    // 左圆
    cloudPath.addOval(Rect.fromLTWH(size.width * 0.32, size.height * 0.32, size.width * 0.28, size.width * 0.28));
    // 右圆
    cloudPath.addOval(Rect.fromLTWH(size.width * 0.52, size.height * 0.25, size.width * 0.32, size.width * 0.32));
    
    // 给云一点柔和投影
    canvas.drawPath(
      cloudPath,
      Paint()
        ..color = isNight ? Colors.black.withValues(alpha: 0.3) : primaryColor.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(cloudPath, cloudPaint);

    // 3. 绘制向上箭头
    final arrowPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.56, size.height * 0.59);
    arrowPath.lineTo(size.width * 0.56, size.height * 0.39);
    arrowPath.moveTo(size.width * 0.48, size.height * 0.47);
    arrowPath.lineTo(size.width * 0.56, size.height * 0.39);
    arrowPath.lineTo(size.width * 0.64, size.height * 0.47);

    canvas.drawPath(arrowPath, arrowPaint);

    // 4. 绘制星星
    final starPaint = Paint()
      ..color = isNight ? const Color(0xFFFFD54F) : primaryColor
      ..style = PaintingStyle.fill;
    
    _drawStar(canvas, Offset(size.width * 0.15, size.height * 0.25), 4, starPaint);
    _drawStar(canvas, Offset(size.width * 0.85, size.height * 0.2), 5, starPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius);
    canvas.drawPath(path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashLength, double gapLength) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + length),
            paint,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TopRightBackgroundPainter extends CustomPainter {
  final bool isNight;
  TopRightBackgroundPainter({required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    if (isNight) return;

    final paint = Paint()..style = PaintingStyle.fill;

    // 1. 绘制极淡的圆形光圈背景
    paint.color = const Color(0xFFE0F2F1).withValues(alpha: 0.2);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.08), 90, paint);

    // 2. 绘制淡淡的心形锁盾牌
    final shieldPaint = Paint()
      ..color = const Color(0xFFB2DFDB).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    
    final shieldPath = Path();
    final center = Offset(size.width * 0.88, size.height * 0.08);
    shieldPath.moveTo(center.dx, center.dy - 25);
    shieldPath.quadraticBezierTo(center.dx + 22, center.dy - 25, center.dx + 22, center.dy);
    shieldPath.quadraticBezierTo(center.dx + 22, center.dy + 15, center.dx, center.dy + 30);
    shieldPath.quadraticBezierTo(center.dx - 22, center.dy + 15, center.dx - 22, center.dy);
    shieldPath.quadraticBezierTo(center.dx - 22, center.dy - 25, center.dx, center.dy - 25);
    canvas.drawPath(shieldPath, shieldPaint);

    final lockPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - 9, center.dy - 2, 18, 14),
        const Radius.circular(3),
      ),
      lockPaint,
    );
    final loopPath = Path();
    loopPath.addArc(Rect.fromLTWH(center.dx - 6, center.dy - 8, 12, 12), 3.14, 3.14);
    canvas.drawPath(loopPath, lockPaint);

    // 3. 绘制淡淡的绿植枝叶
    final leafPaint = Paint()
      ..color = const Color(0xFFA5D6A7).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final stemPaint = Paint()
      ..color = const Color(0xFFA5D6A7).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final stemPath = Path();
    stemPath.moveTo(size.width * 0.72, size.height * 0.12);
    stemPath.quadraticBezierTo(size.width * 0.78, size.height * 0.07, size.width * 0.88, size.height * 0.03);
    canvas.drawPath(stemPath, stemPaint);

    _drawLeaf(canvas, Offset(size.width * 0.76, size.height * 0.09), 3.14 * -0.25, leafPaint);
    _drawLeaf(canvas, Offset(size.width * 0.82, size.height * 0.06), 3.14 * -0.25, leafPaint);
    _drawLeaf(canvas, Offset(size.width * 0.87, size.height * 0.035), 3.14 * -0.15, leafPaint);
  }

  void _drawLeaf(Canvas canvas, Offset position, double rotation, Paint paint) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    
    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(10, -5, 15, 0);
    path.quadraticBezierTo(5, 5, 0, 0);
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BottomDecorationWidget extends StatelessWidget {
  final bool isNight;
  const BottomDecorationWidget({super.key, required this.isNight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 30,
      child: CustomPaint(
        painter: BottomDecorationPainter(isNight: isNight),
      ),
    );
  }
}

class BottomDecorationPainter extends CustomPainter {
  final bool isNight;
  BottomDecorationPainter({required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    final color = isNight ? Colors.white24 : const Color(0xFFD7CCC8);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);

    final shieldPath = Path();
    shieldPath.moveTo(center.dx, center.dy - 8);
    shieldPath.quadraticBezierTo(center.dx + 7, center.dy - 8, center.dx + 7, center.dy - 1);
    shieldPath.quadraticBezierTo(center.dx + 7, center.dy + 4, center.dx, center.dy + 9);
    shieldPath.quadraticBezierTo(center.dx - 7, center.dy + 4, center.dx - 7, center.dy - 1);
    shieldPath.quadraticBezierTo(center.dx - 7, center.dy - 8, center.dx, center.dy - 8);
    canvas.drawPath(shieldPath, paint);

    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy), 1.5, innerPaint);

    final leftLine = Path();
    leftLine.moveTo(center.dx - 18, center.dy);
    leftLine.lineTo(center.dx - 55, center.dy);
    canvas.drawPath(leftLine, paint);
    
    _drawSmallLeaf(canvas, Offset(center.dx - 28, center.dy), 3.14 * 0.75, color);
    _drawSmallLeaf(canvas, Offset(center.dx - 38, center.dy), 3.14 * 0.75, color);
    _drawSmallLeaf(canvas, Offset(center.dx - 48, center.dy), 3.14 * 0.75, color);

    final rightLine = Path();
    rightLine.moveTo(center.dx + 18, center.dy);
    rightLine.lineTo(center.dx + 55, center.dy);
    canvas.drawPath(rightLine, paint);

    _drawSmallLeaf(canvas, Offset(center.dx + 28, center.dy), 3.14 * 0.25, color);
    _drawSmallLeaf(canvas, Offset(center.dx + 38, center.dy), 3.14 * 0.25, color);
    _drawSmallLeaf(canvas, Offset(center.dx + 48, center.dy), 3.14 * 0.25, color);
  }

  void _drawSmallLeaf(Canvas canvas, Offset pos, double angle, Color color) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(5, -3, 8, 0);
    path.quadraticBezierTo(3, 3, 0, 0);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
