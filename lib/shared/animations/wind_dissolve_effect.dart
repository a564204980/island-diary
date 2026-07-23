import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:island_diary/core/services/wind_service.dart';

/// 粒子数据模型
class _WindParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double vx;
  final double vy;
  final double vRot;
  final bool isCircle;

  _WindParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.vx,
    required this.vy,
    required this.vRot,
    required this.isCircle,
  });
}

/// 海岛随风消逝粒子特效动画组件
class WindDissolveEffectWidget extends StatefulWidget {
  final Offset position;
  final Size size;
  final double angle;
  final WindMode windMode;
  final VoidCallback onComplete;

  const WindDissolveEffectWidget({
    super.key,
    required this.position,
    required this.size,
    required this.angle,
    required this.windMode,
    required this.onComplete,
  });

  @override
  State<WindDissolveEffectWidget> createState() => _WindDissolveEffectWidgetState();
}

class _WindDissolveEffectWidgetState extends State<WindDissolveEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_WindParticle> _particles;

  static const List<Color> _macaronColors = [
    Color(0xFFFFB7B2), // 马卡龙柔粉
    Color(0xFFB5EAD7), // 薄荷绿
    Color(0xFFFFE5B4), // 奶油暖黄
    Color(0xFFE2D4F0), // 薰衣草浅紫
    Color(0xFFC7CEEA), // 天空柔蓝
    Color(0xFFFFF9F0), // 燕麦白
    Color(0xFFFFD56B), // 治愈暖金
  ];

  @override
  void initState() {
    super.initState();
    _generateParticles();

    Duration duration;
    switch (widget.windMode) {
      case WindMode.none:
        duration = const Duration(milliseconds: 850);
        break;
      case WindMode.breeze:
        duration = const Duration(milliseconds: 700);
        break;
      case WindMode.moderate:
        duration = const Duration(milliseconds: 550);
        break;
      case WindMode.gale:
        duration = const Duration(milliseconds: 400);
        break;
    }

    _controller = AnimationController(
      vsync: this,
      duration: duration,
    );

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  void _generateParticles() {
    final rand = math.Random();
    const particleCount = 45;
    _particles = List.generate(particleCount, (i) {
      final px = rand.nextDouble() * widget.size.width;
      final py = rand.nextDouble() * widget.size.height;
      final pSize = 2.5 + rand.nextDouble() * 5.5;
      final color = _macaronColors[rand.nextInt(_macaronColors.length)];
      final isCircle = rand.nextBool();

      double baseVx, baseVy;
      switch (widget.windMode) {
        case WindMode.none:
          baseVx = (rand.nextDouble() - 0.5) * 40.0;
          baseVy = 30.0 + rand.nextDouble() * 70.0;
          break;
        case WindMode.breeze:
          baseVx = -(100.0 + rand.nextDouble() * 120.0);
          baseVy = -60.0 + (rand.nextDouble() - 0.5) * 60.0;
          break;
        case WindMode.moderate:
          baseVx = -(250.0 + rand.nextDouble() * 200.0);
          baseVy = -120.0 + (rand.nextDouble() - 0.5) * 100.0;
          break;
        case WindMode.gale:
          baseVx = -(500.0 + rand.nextDouble() * 400.0);
          baseVy = -180.0 + (rand.nextDouble() - 0.5) * 150.0;
          break;
      }

      return _WindParticle(
        x: px,
        y: py,
        size: pSize,
        color: color,
        vx: baseVx,
        vy: baseVy,
        vRot: (rand.nextDouble() - 0.5) * 10.0,
        isCircle: isCircle,
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
          painter: _WindDissolvePainter(
            particles: _particles,
            progress: _controller.value,
            baseOffset: widget.position,
            cardSize: widget.size,
            cardAngle: widget.angle,
          ),
        );
      },
    );
  }
}

class _WindDissolvePainter extends CustomPainter {
  final List<_WindParticle> particles;
  final double progress;
  final Offset baseOffset;
  final Size cardSize;
  final double cardAngle;

  _WindDissolvePainter({
    required this.particles,
    required this.progress,
    required this.baseOffset,
    required this.cardSize,
    required this.cardAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final curveProgress = Curves.easeOutCubic.transform(progress);

    final center = Offset(
      baseOffset.dx + cardSize.width / 2,
      baseOffset.dy + cardSize.height / 2,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(cardAngle);

    final halfW = cardSize.width / 2;
    final halfH = cardSize.height / 2;

    for (final p in particles) {
      final currentX = (p.x - halfW) + p.vx * curveProgress;
      final currentY = (p.y - halfH) + p.vy * curveProgress;
      final currentScale = (1.0 - curveProgress * 0.4).clamp(0.1, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(p.vRot * curveProgress);
      canvas.scale(currentScale);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.8),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(rrect, paint);
      }

      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WindDissolvePainter oldDelegate) => true;
}
