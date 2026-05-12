import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 磨砂质感彩虹组件
/// 每种颜色是独立的同心弧线，从外到内依次是：红橙黄绿蓝紫
/// 各色带半径由粗细自动推算，改变粗细后色带始终紧贴
class FrostedRainbow extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;

  const FrostedRainbow({
    super.key,
    this.width = 400,
    this.height = 300,
    this.opacity = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _RainbowPainter(opacity: opacity)),
    );
  }
}

class _RainbowPainter extends CustomPainter {
  final double opacity;

  const _RainbowPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    // 圆心在画布下方，弧线横跨整个宽度
    final cx = size.width / 1.1;
    final cy = size.height * 1.05;
    final center = Offset(cx, cy);

    // 基础参考半径（最外层红色弧的外边缘）
    final baseR = cy - size.height * 0.35;

    // 基础粗细单元——调整此值可整体缩放彩虹宽度
    final t = size.height * 0.055;

    // ---- 色带定义：只填 [颜色, 粗细, 模糊] ----
    final bandDefs = <(Color, double, double)>[
      (const Color(0xFFFF4444), t * 0.4, 7.0), // 红
      (const Color(0xFFFF9040), t * 0.3, 7.0), // 橙
      (const Color(0xFFFFE033), t * 0.3, 5.0), // 黄
      (const Color(0xFF50DD68), t * 0.3, 5.0), // 绿
      (const Color(0xFF4DAAFF), t * 0.3, 7.0), // 蓝
      (const Color(0xFF9B6FD4), t * 0.4, 7.0), // 紫
    ];

    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // 从外边缘开始，依次向内推算每条弧的圆心半径
    double cursor = baseR; // 当前外边缘位置
    final resolvedBands = <(Color, double, double, double)>[];
    for (final def in bandDefs) {
      final strokeW = def.$2;
      final centerR = cursor - strokeW / 2;
      resolvedBands.add((def.$1, centerR, strokeW, def.$3));
      cursor -= strokeW; // 下一条从此条内边缘开始
    }
    final innerEdge = cursor; // 最内层边缘位置

    // 外层漫射大发光
    _drawArc(
      canvas,
      center,
      baseR + t * 1.5,
      t * 5,
      35,
      startAngle,
      sweepAngle,
      const Color(0xFFFF4444).withValues(alpha: 0.18 * opacity),
    );

    // 各色带
    for (final b in resolvedBands) {
      _drawArc(
        canvas,
        center,
        b.$2,
        b.$3,
        b.$4,
        startAngle,
        sweepAngle,
        b.$1.withValues(alpha: 0.78 * opacity),
      );
    }

    // 内层收边发光
    _drawArc(
      canvas,
      center,
      innerEdge + t * 0.4,
      t * 2,
      18,
      startAngle,
      sweepAngle,
      const Color(0xFF9B6FD4).withValues(alpha: 0.2 * opacity),
    );

    // 磨砂颗粒感
    _drawGrain(canvas, center, innerEdge, baseR + t * 1.5);
  }

  void _drawArc(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeW,
    double blurSigma,
    double startAngle,
    double sweepAngle,
    Color color,
  ) {
    if (radius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.butt
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma)
        ..color = color,
    );
  }

  void _drawGrain(Canvas canvas, Offset center, double innerR, double outerR) {
    final random = math.Random(42);
    final grainPaint = Paint();
    final totalW = outerR - innerR;

    for (int i = 0; i < 8000; i++) {
      final angle = math.pi + random.nextDouble() * math.pi;
      final dist = innerR + random.nextDouble() * totalW;
      final x = center.dx + math.cos(angle) * dist;
      final y = center.dy + math.sin(angle) * dist;

      grainPaint.color = Colors.white.withValues(
        alpha: random.nextDouble() * 0.15 * opacity,
      );
      canvas.drawCircle(
        Offset(x, y),
        0.3 + random.nextDouble() * 0.7,
        grainPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainbowPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
