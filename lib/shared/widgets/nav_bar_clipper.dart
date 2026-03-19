import 'dart:math';
import 'package:flutter/material.dart';

class NavBarClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double barRadius;

  const NavBarClipper({required this.notchRadius, required this.barRadius});

  @override
  Path getClip(Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    path.moveTo(barRadius, 0);

    // ── 严格几何相切圆方案 (100% 数学无缝衔接) ──
    const double notchMargin = -8.0; // 凹口与悬浮按钮的间距
    final double r = notchRadius + notchMargin; // 凹口主圆半径
    const double rs = 16.0; // 裙边过渡圆角半径 (越大越平缓)

    // 几何相切计算
    final double d = r + rs; // 两圆心距离
    final double dx = sqrt(d * d - rs * rs); // 裙边圆心水平距离

    // 相切交点坐标偏移量
    final double tangentOffsetX = dx * (r / d);
    final double tangentY = rs * (r / d);

    // 裙边圆起点 X
    final double leftShoulderX = cx - dx;
    final double rightShoulderX = cx + dx;

    // 绘制路径
    path.lineTo(leftShoulderX, 0);

    // 🌟 第一段：左侧裙边 (顺时针，向内凹)
    path.arcToPoint(
      Offset(cx - tangentOffsetX, tangentY),
      radius: const Radius.circular(rs),
      clockwise: true,
    );

    // 🌟 第二段：主凹口 (逆时针，向上托盘)
    path.arcToPoint(
      Offset(cx + tangentOffsetX, tangentY),
      radius: Radius.circular(r),
      clockwise: false,
    );

    // 🌟 第三段：右侧裙边 (顺时针，回归直线)
    path.arcToPoint(
      Offset(rightShoulderX, 0),
      radius: const Radius.circular(rs),
      clockwise: true,
    );

    path.lineTo(w - barRadius, 0);
    path.quadraticBezierTo(w, 0, w, barRadius);
    path.lineTo(w, h - barRadius);
    path.quadraticBezierTo(w, h, w - barRadius, h);
    path.lineTo(barRadius, h);
    path.quadraticBezierTo(0, h, 0, h - barRadius);
    path.lineTo(0, barRadius);
    path.quadraticBezierTo(0, 0, barRadius, 0);

    return path;
  }

  @override
  bool shouldReclip(covariant NavBarClipper oldClipper) =>
      oldClipper.notchRadius != notchRadius || oldClipper.barRadius != barRadius;
}

class NavBarGradientPainter extends CustomPainter {
  final CustomClipper<Path> clipper;
  final double strokeWidth;
  final Gradient gradient;

  NavBarGradientPainter({
    required this.clipper,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(Offset.zero & size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant NavBarGradientPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth || oldDelegate.gradient != gradient;
}
