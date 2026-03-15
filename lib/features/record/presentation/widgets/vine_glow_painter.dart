import 'package:flutter/material.dart';
import 'vine_render_helper.dart';

/// 藤蔓路径微光描边绘制器
class VineGlowPainter extends CustomPainter {
  final double totalHeight;
  final bool isNight;

  VineGlowPainter({required this.totalHeight, required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 构建藤蔓主干路径
    final path = Path();
    const double step = 20.0;
    
    path.moveTo(VineRenderHelper.getVineXAt(0) + 200, 0);
    for (double y = step; y < totalHeight; y += step) {
      final x = VineRenderHelper.getVineXAt(y) + 200;
      path.lineTo(x, y);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // --- 核心颜色：深一度的暖金色 ---
    final glowColor = const Color(0xFFFFCA28); // 使用更饱和的暖金 (Amber 400)

    // 2. 绘制多层发光效果

    // 第一层：广域背景氛围 (提升饱和度)
    paint.color = glowColor.withOpacity(isNight ? 0.08 : 0.06);
    paint.strokeWidth = 38;
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawPath(path, paint);

    // 第二层：主体发光 (加亮加厚)
    paint.color = glowColor.withOpacity(isNight ? 0.18 : 0.14);
    paint.strokeWidth = 20;
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, paint);

    // 第三层：强化高亮边缘层 (颜色调深，亮度加浓)
    paint.color = const Color(0xFFFFE082).withOpacity(isNight ? 0.6 : 0.75);
    paint.strokeWidth = 3.0; // 稍微加粗 0.5px 提高结构感
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant VineGlowPainter oldDelegate) {
    return oldDelegate.totalHeight != totalHeight || oldDelegate.isNight != isNight;
  }
}
