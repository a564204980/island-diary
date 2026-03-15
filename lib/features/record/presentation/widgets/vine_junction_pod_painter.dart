import 'package:flutter/material.dart';

/// 藤蔓素材衔接点专用发光点 (Junction Pod) - 体积更大、发光更散，用于掩盖接缝
class VineJunctionPodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // --- 核心颜色：深暖金 (强化饱和度，对标浓郁 UI 感) ---
    final baseGold = const Color(0xFFFF9100); // 更改为更鲜艳的暖橙色 (Orange Accent 400)

    // 1. 底层：超广域柔和氛围光 (加深浓度)
    paint.color = baseGold.withOpacity(0.18); 
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 65);
    canvas.drawCircle(center, 170, paint);

    // 2. 中层：主体扩散光 (提升色彩存在感)
    paint.color = baseGold.withOpacity(0.35); 
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 32);
    canvas.drawCircle(center, 105, paint);

    // 3. 核心层：高浓度氛围圈 (形成浑厚的光团)
    paint.color = baseGold.withOpacity(0.55);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, 75, paint);

    // 4. 高亮层：极其鲜艳的核心 (模拟强光)
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFFFD180).withOpacity(0.95); // 使用暖黄色提高核心亮度
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, 45, paint);

    // 5. 极亮点：强力纯白点 (极致对比)
    paint.color = Colors.white.withOpacity(0.85);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, 15, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
