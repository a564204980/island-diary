import 'dart:math';
import 'package:flutter/material.dart';

class StarfieldBackground extends StatefulWidget {
  const StarfieldBackground({super.key});

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Star> _stars;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _generateStars();
  }

  void _generateStars() {
    _stars = List.generate(150, (index) {
      // 核心魔法：使用平方（或稍微大一点如 2.5 次方），让随机数在 0~1 范围内大幅度偏向 0 (顶部)
      // 越往下分布越稀疏
      final double rawY = _random.nextDouble();
      final double yPos = pow(rawY, 2.5).toDouble();

      // 底部的星星相对更小，加强纵深的微光地平线感
      final double baseSizeRange = 2.0 - yPos * 1.2;

      return Star(
        x: _random.nextDouble(), // 0.0 to 1.0 (relative width)
        y: yPos, // 基于衰减算法的纵向分布
        size:
            _random.nextDouble() * baseSizeRange +
            0.5, // 0.5 to (0.5 + baseSizeRange)
        baseOpacity: _random.nextDouble() * 0.5 + 0.3, // 0.3 to 0.8
        blinkPhase: _random.nextDouble() * pi * 2,
        blinkSpeed: _random.nextDouble() * 0.5 + 0.5,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: StarfieldPainter(
            stars: _stars,
            animationValue: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Star {
  final double x, y, size, baseOpacity, blinkPhase, blinkSpeed;
  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.baseOpacity,
    required this.blinkPhase,
    required this.blinkSpeed,
  });
}

class StarfieldPainter extends CustomPainter {
  final List<Star> stars;
  final double animationValue;

  StarfieldPainter({required this.stars, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 基础星空涂料
    final Paint starPaint = Paint()..color = Colors.white;

    // 绘制呼吸闪烁的星星

    for (var star in stars) {
      // 结合 animationValue 和每个星星自身的初始相位+速率，制造不规则的错落闪烁感
      final double currentPhase =
          star.blinkPhase + (animationValue * pi * 2 * star.blinkSpeed);
      final double flicker = (sin(currentPhase) + 1) / 2; // 0.0 to 1.0

      final double currentOpacity = (star.baseOpacity * flicker).clamp(
        0.1,
        1.0,
      );

      starPaint.color = Colors.white.withOpacity(currentOpacity);

      final Offset position = Offset(star.x * size.width, star.y * size.height);
      canvas.drawCircle(position, star.size, starPaint);

      // 给较大的星星加一点微光晕，看起来更梦幻
      if (star.size > 1.2) {
        final Paint glowPaint = Paint()
          ..color = Colors.white.withOpacity(currentOpacity * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawCircle(position, star.size * 2.5, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
