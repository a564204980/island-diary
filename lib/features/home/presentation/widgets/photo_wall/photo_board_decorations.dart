import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 照片墙手撕和纸胶带配置模型
class WashiTapeConfig {
  final Color color;
  final double angle;
  final bool isLeft;
  final double width;
  final double height;

  const WashiTapeConfig({
    required this.color,
    required this.angle,
    required this.isLeft,
    required this.width,
    required this.height,
  });
}

/// 3D 水晶图钉组件
class PushPinWidget extends StatelessWidget {
  final int index;
  final double pinSize;

  const PushPinWidget({
    super.key,
    required this.index,
    this.pinSize = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    const pinColors = [
      Color(0xFFFF8B8B),
      Color(0xFF6BD2B0),
      Color(0xFFFFC04D),
      Color(0xFFB89FE1),
      Color(0xFF88A3EC),
    ];
    final color = pinColors[index % pinColors.length];
    final highlightColor = Color.lerp(color, Colors.white, 0.70)!;
    final shadowColor = Color.lerp(color, const Color(0xFF2C1A1D), 0.50)!;

    return SizedBox(
      width: pinSize,
      height: pinSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 斜向软阴影
          Positioned(
            top: pinSize * 0.18,
            left: pinSize * 0.10,
            child: Container(
              width: pinSize - 2,
              height: pinSize - 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
          ),

          // 金属座圈
          Container(
            width: pinSize,
            height: pinSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFB0B0B0),
            ),
          ),

          // 水晶半球主体
          Container(
            margin: const EdgeInsets.all(0.8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.45),
                radius: 0.78,
                colors: [highlightColor, color, shadowColor],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // 顶部小高光点
          Positioned(
            top: pinSize * 0.20,
            left: pinSize * 0.24,
            child: Container(
              width: pinSize * 0.28,
              height: pinSize * 0.18,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.all(Radius.elliptical(pinSize * 0.14, pinSize * 0.09)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 手撕撕裂和纸胶带 CustomPainter (包含锯齿边缘、半透明滤质与微光纤维)
class WashiTapePainter extends CustomPainter {
  final Color color;

  WashiTapePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;

    final path = Path();
    const int numTeeth = 4;
    final toothH = size.height / numTeeth;

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    // 右侧锯齿撕裂边
    for (int i = 0; i < numTeeth; i++) {
      final yMid = (i + 0.5) * toothH;
      final yEnd = (i + 1) * toothH;
      final dx = (i % 2 == 0) ? -2.5 : 0.0;
      path.lineTo(size.width + dx, yMid);
      path.lineTo(size.width, yEnd);
    }

    path.lineTo(0, size.height);

    // 左侧锯齿撕裂边
    for (int i = numTeeth - 1; i >= 0; i--) {
      final yMid = (i + 0.5) * toothH;
      final yStart = i * toothH;
      final dx = (i % 2 == 0) ? 2.5 : 0.0;
      path.lineTo(dx, yMid);
      path.lineTo(0, yStart);
    }

    path.close();

    // 1. 底层接触下落微阴影
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawPath(path.shift(const Offset(0.8, 1.2)), shadowPaint);

    // 2. 胶带主体填充
    canvas.drawPath(path, paint);

    // 3. 顶部微光亮线
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.40)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(2, 1), Offset(size.width - 2, 1), shinePaint);

    // 4. 和纸纵向纤维微纹
    final fiberPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.3, 2), Offset(size.width * 0.3 + 3, size.height - 2), fiberPaint);
    canvas.drawLine(Offset(size.width * 0.7, 2), Offset(size.width * 0.7 - 3, size.height - 2), fiberPaint);
  }

  @override
  bool shouldRepaint(covariant WashiTapePainter oldDelegate) =>
      color != oldDelegate.color;
}

/// 手帐选中虚线框绘制类
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dash = 6.0,
    this.gap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-3, -3, size.width + 6, size.height + 6),
      const Radius.circular(9),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = math.min(dash, metric.length - distance);
        dashPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color;
}
