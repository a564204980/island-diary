import 'dart:math' as math;
import 'package:flutter/material.dart';

class Fireflies extends StatefulWidget {
  final int count;
  const Fireflies({super.key, this.count = 15});

  @override
  State<Fireflies> createState() => _FirefliesState();
}

class _FirefliesState extends State<Fireflies> with TickerProviderStateMixin {
  late List<_FireflyModel> _fireflies;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _fireflies = List.generate(widget.count, (index) => _FireflyModel(vsync: this, random: _random));
  }

  @override
  void dispose() {
    for (var f in _fireflies) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: _fireflies.map((f) {
            return AnimatedBuilder(
              animation: Listenable.merge([f.moveController, f.pulseController]),
              builder: (context, child) {
                // 计算当前位置
                final x = f.startX + (f.targetX - f.startX) * f.moveController.value;
                final y = f.startY + (f.targetY - f.startY) * f.moveController.value;
                
                return Positioned(
                  left: x * constraints.maxWidth,
                  top: y * constraints.maxHeight,
                  child: Container(
                    width: f.size,
                    height: f.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEFFF8E).withValues(alpha: f.pulseAnimation.value),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4FF00).withValues(alpha: 0.8 * f.pulseAnimation.value),
                          blurRadius: f.size * 2,
                          spreadRadius: f.size / 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _FireflyModel {
  late double startX, startY;
  late double targetX, targetY;
  late double size;
  late AnimationController moveController;
  late AnimationController pulseController;
  late Animation<double> pulseAnimation;
  final math.Random random;

  _FireflyModel({required TickerProvider vsync, required this.random}) {
    startX = random.nextDouble();
    startY = random.nextDouble();
    _setNewTarget();
    size = 2.0 + random.nextDouble() * 2.0;

    moveController = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: 3000 + random.nextInt(5000)),
    );

    pulseController = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: 1000 + random.nextInt(2000)),
    );

    pulseAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );

    moveController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        startX = targetX;
        startY = targetY;
        _setNewTarget();
        moveController.duration = Duration(milliseconds: 4000 + random.nextInt(6000));
        moveController.forward(from: 0);
      }
    });

    pulseController.repeat(reverse: true);
    moveController.forward();
  }

  void _setNewTarget() {
    // 限制移动范围，避免跳跃太大
    targetX = (startX + (random.nextDouble() * 0.4 - 0.2)).clamp(0.0, 1.0);
    targetY = (startY + (random.nextDouble() * 0.4 - 0.2)).clamp(0.0, 1.0);
  }

  void dispose() {
    moveController.dispose();
    pulseController.dispose();
  }
}
