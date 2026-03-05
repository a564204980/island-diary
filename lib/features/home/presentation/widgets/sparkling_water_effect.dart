import 'dart:math';
import 'package:flutter/material.dart';

/// 湖面波光粼粼特效组件
class SparklingWaterEffect extends StatefulWidget {
  final int particleCount;

  const SparklingWaterEffect({
    super.key,
    this.particleCount = 80, // 默认生成 80 个波光点
  });

  @override
  State<SparklingWaterEffect> createState() => _SparklingWaterEffectState();
}

class _SparklingWaterEffectState extends State<SparklingWaterEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Sparkle> _sparkles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // 动画周期长一点，保证闪烁更加缓慢自然
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // 预先生成所有的波光点数据（归一化坐标 0.0 ~ 1.0）
    for (int i = 0; i < widget.particleCount; i++) {
      _sparkles.add(
        _Sparkle(
          x: _random.nextDouble(),
          // 假设湖面大约占据画面的下半部分，这里从 Y = 0.4 开始到 1.0
          y: 0.45 + _random.nextDouble() * 0.55,
          // 宽度长条形，模拟水面的横向波纹反光
          width: 4.0 + _random.nextDouble() * 15.0,
          height: 1.0 + _random.nextDouble() * 1.5,
          // 相位：决定闪烁的错落感
          phase: _random.nextDouble() * 2 * pi,
          // 闪烁速度
          speed: 0.5 + _random.nextDouble() * 2.0,
          // 波光的最高亮度
          maxOpacity: 0.2 + _random.nextDouble() * 0.6,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 忽略点击事件，让它完全透明，不影响底层的任何手势
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _SparklePainter(
              sparkles: _sparkles,
              // 根据动画进度算出 time (0 ~ 2pi)
              time: _controller.value * 2 * pi,
            ),
          );
        },
      ),
    );
  }
}

class _Sparkle {
  final double x, y, width, height, phase, speed, maxOpacity;
  _Sparkle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.phase,
    required this.speed,
    required this.maxOpacity,
  });
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double time;

  _SparklePainter({required this.sparkles, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      // 增加轻微的发光模糊效果，让波光显得更加梦幻和柔和
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    for (var sparkle in sparkles) {
      // 利用正弦函数计算出带有呼吸感的透明度
      final currentOpacity =
          (sin(time * sparkle.speed + sparkle.phase) + 1.0) /
          2.0 *
          sparkle.maxOpacity;

      // 去掉横向漂移，只保留原地呼吸闪烁，让夏日湖面的波光更加纯净静谧
      final absoluteX = sparkle.x * size.width;
      final absoluteY = sparkle.y * size.height;

      paint.color = Colors.white.withOpacity(currentOpacity);

      // 绘制带圆角的横扁长方形，模拟微波涟漪反光
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(absoluteX, absoluteY),
          width: sparkle.width,
          height: sparkle.height,
        ),
        Radius.circular(sparkle.height / 2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.time != time; // 每帧重绘
  }
}
