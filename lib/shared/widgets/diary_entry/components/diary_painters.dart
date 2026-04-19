import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 精细化手绘风格标签背景绘制器（支持外发光与水彩“花色”背景）
class HandDrawnTagPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  HandDrawnTagPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _createOrganicPath(size);

    // 1. 绘制复合外发光 (Glow Effect)
    _drawOuterGlow(canvas, path);

    // 2. 绘制基础背景
    final basePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, basePaint);

    // 3. 绘制“花色”水彩纹理
    _drawWatercolorTexture(canvas, size, path);

    // 4. 绘制主边框线条（圆润写意）
    final borderPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, borderPaint);

    // 5. 断续草稿复笔
    final extraPath = _createOrganicPath(size, offset: 0.8);
    canvas.drawPath(
      extraPath,
      borderPaint
        ..strokeWidth = 0.4
        ..color = borderColor.withValues(alpha: 0.12),
    );
  }

  /// 绘制多层复合外发光（白色柔光 + 核心阴影）
  void _drawOuterGlow(Canvas canvas, Path path) {
    // 基础柔和投影
    canvas.drawShadow(
      path.shift(const Offset(0, 1)),
      Colors.black.withValues(alpha: 0.1),
      4.0,
      true,
    );

    // 白色外发光扩散感
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawPath(path, glowPaint);
  }

  /// 绘制模拟水彩纸的“花色”纹理
  void _drawWatercolorTexture(Canvas canvas, Size size, Path clipPath) {
    canvas.save();
    canvas.clipPath(clipPath);

    final random = math.Random(12345); // 固定种子

    // A. 基础多色晕染（形成“花”的基调，参考图中的青、粉色调）
    final List<Map<String, dynamic>> blooms = [
      {
        'color': const Color(0xFFA2D2FF),
        'center': const Alignment(0.8, -0.6),
        'radius': 1.6,
      },
      {
        'color': const Color(0xFFFFC2D1),
        'center': const Alignment(-0.7, 0.4),
        'radius': 1.3,
      },
      {
        'color': const Color(0xFFD8F3DC),
        'center': const Alignment(0.5, 0.8),
        'radius': 1.0,
      },
      {
        'color': const Color(0xFFFFF7ED),
        'center': const Alignment(-0.9, -0.9),
        'radius': 1.2,
      },
    ];

    for (var bloom in blooms) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            (bloom['color'] as Color).withValues(alpha: 0.18),
            Colors.transparent,
          ],
          center: bloom['center'] as Alignment,
          radius: bloom['radius'] as double,
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, paint);
    }

    // B. 随机“花点”纹理（模拟水彩纸张的细节噪点）
    for (int i = 0; i < 25; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double dotRadius = random.nextDouble() * 3 + 1;

      final colorType = random.nextInt(3);
      Color dotColor;
      if (colorType == 0) {
        dotColor = const Color(0xFFA2D2FF);
      } else if (colorType == 1) {
        dotColor = const Color(0xFFFFC2D1);
      } else {
        dotColor = const Color(0xFFE2B6FF);
      }

      final dotPaint = Paint()
        ..color = dotColor.withValues(alpha: 0.08)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          random.nextDouble() * 1.5 + 0.5,
        );

      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
    }

    canvas.restore();
  }

  /// 创建一个具有圆润感和轻微波动的有机矩形路径
  Path _createOrganicPath(Size size, {double offset = 0}) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;
    final double r = 16.0;

    path.moveTo(r + offset, offset);
    path.quadraticBezierTo(w / 2, -0.6 + offset, w - r - offset, offset + 0.3);
    path.quadraticBezierTo(
      w + 0.2 - offset,
      offset + 0.2,
      w - offset,
      r + offset,
    );
    path.quadraticBezierTo(w + 0.8 - offset, h / 2, w - offset, h - r - offset);
    path.quadraticBezierTo(
      w - 0.2 - offset,
      h + 0.4 - offset,
      w - r - offset,
      h - offset,
    );
    path.quadraticBezierTo(
      w / 2,
      h + 0.6 - offset,
      r + offset,
      h - offset + 0.2,
    );
    path.quadraticBezierTo(
      offset - 0.4,
      h + 0.2 - offset,
      offset,
      h - r - offset,
    );
    path.quadraticBezierTo(offset - 0.6, h / 2, offset + 0.2, r + offset);
    path.quadraticBezierTo(offset + 0.1, offset - 0.5, r + offset, offset);

    return path;
  }

  @override
  bool shouldRepaint(covariant HandDrawnTagPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}

/// 手绘风格工具栏背景绘制器
class HandDrawnToolbarPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool shadowOnly;
  final bool showSideBorders;

  HandDrawnToolbarPainter({
    required this.color,
    required this.borderColor,
    this.shadowOnly = false,
    this.showSideBorders = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 创建带波动感的手绘路径
    final path = Path();
    final w = size.width;
    final h = size.height;

    // 1. 顶部边缘 (向右)
    path.moveTo(2, 5);
    int step = 0;
    for (double i = 0; i <= w; i += 20) {
      final double x = i > w ? w : i;
      path.lineTo(x, 2.0 + (step % 2 == 0 ? 3.0 : 0.0));
      step++;
    }

    // 2. 右侧边缘 (向下)
    step = 0;
    for (double y = 0; y <= h; y += 15) {
      final double currentY = y > h ? h : y;
      path.lineTo(w - 1.0 - (step % 2 == 0 ? 3.0 : 0.0), currentY);
      step++;
    }

    // 3. 底部边缘 (直线)
    path.lineTo(w, h);
    path.lineTo(0, h);

    // 4. 左侧边缘 (向上)
    step = 0;
    for (double y = h; y >= 0; y -= 15) {
      final double currentY = y < 0 ? 0 : y;
      path.lineTo(1.0 + (step % 2 == 0 ? 3.0 : 0.0), currentY);
      step++;
    }

    path.close();

    // 1. 绘制阴影 (仅在 shadowOnly 为 true 时，或普通绘制的第一步)
    if (shadowOnly) {
      canvas.drawShadow(
        path.shift(const Offset(0, 4)),
        Colors.black.withValues(alpha: 0.15),
        10.0,
        true,
      );
      return;
    }

    // 2. 绘制基础填充
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // 3. 绘制边框线条 (加粗，但减弱透明度以达到轻盈感)
    final linePaint = Paint()
      ..color = borderColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    // A. 顶部线条
    final topPath = Path();
    topPath.moveTo(0, 5);
    for (double i = 0; i <= w; i += 30) {
      topPath.lineTo(i, 3.0 + (i % 60 == 0 ? 2.0 : -0.5));
    }
    topPath.lineTo(w, 3.0);
    canvas.drawPath(topPath, linePaint);

    // B. 侧边线条 (仅在宽屏/iPad 模式下显示)
    if (showSideBorders) {
      // 左侧
      final leftPath = Path();
      leftPath.moveTo(2, 5);
      step = 0;
      for (double y = 0; y <= h; y += 20) {
        final double currentY = y > h ? h : y;
        leftPath.lineTo(1.0 + (step % 2 == 0 ? 2.0 : -0.5), currentY);
        step++;
      }
      canvas.drawPath(leftPath, linePaint);

      // 右侧
      final rightPath = Path();
      rightPath.moveTo(w - 2, 5);
      step = 0;
      for (double y = 0; y <= h; y += 20) {
        final double currentY = y > h ? h : y;
        rightPath.lineTo(w - 1.0 - (step % 2 == 0 ? 2.0 : -0.5), currentY);
        step++;
      }
      canvas.drawPath(rightPath, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HandDrawnToolbarPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.shadowOnly != shadowOnly ||
      oldDelegate.showSideBorders != showSideBorders;
}

/// 日记信纸背景绘制总调度
class PaperBackgroundPainter extends CustomPainter {
  final String style;
  final bool isNight;
  final Color accentColor;

  PaperBackgroundPainter({
    required this.style,
    required this.isNight,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Current design only uses the base background color or external image.
    // The previous complex textures have been removed for simplicity.
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
