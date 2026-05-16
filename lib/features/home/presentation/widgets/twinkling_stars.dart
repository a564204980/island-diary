import 'dart:math' as math;
import 'package:flutter/material.dart';

class TwinklingStars extends StatefulWidget {
  final int count;
  final bool shouldAnimate;

  const TwinklingStars({
    super.key,
    this.count = 40,
    this.shouldAnimate = true,
  });

  @override
  State<TwinklingStars> createState() => _TwinklingStarsState();
}

class _TwinklingStarsState extends State<TwinklingStars> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_StarModel> _stars;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _initStars();
  }

  void _initStars() {
    _stars = List.generate(widget.count, (index) {
      return _StarModel(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 0.7, // 主要分布在屏幕上半部分
        size: 1.0 + _random.nextDouble() * 3.0,
        type: _random.nextDouble() > 0.8 ? _StarType.cross : _StarType.dot,
        twinkleSpeed: 0.5 + _random.nextDouble() * 1.5,
        seed: _random.nextDouble() * math.pi * 2,
        opacityBase: 0.3 + _random.nextDouble() * 0.4,
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
    if (!widget.shouldAnimate) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double time = DateTime.now().millisecondsSinceEpoch.toDouble();
        
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: _stars.map((star) {
                // 使用绝对时间计算闪烁，实现无限连续的呼吸感
                double opacity = star.opacityBase + math.sin(time * 0.001 * star.twinkleSpeed + star.seed) * 0.3;
                opacity = opacity.clamp(0.1, 1.0);

                return Positioned(
                  left: star.x * constraints.maxWidth,
                  top: star.y * constraints.maxHeight,
                  child: Opacity(
                    opacity: opacity,
                    child: _buildStarWidget(star),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildStarWidget(_StarModel star) {
    if (star.type == _StarType.cross) {
      // 带有十字光芒的星星
      return Stack(
        alignment: Alignment.center,
        children: [
          // 核心圆点
          Container(
            width: star.size,
            height: star.size,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEFA1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFFD180),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // 横向光芒
          Container(
            width: star.size * 4,
            height: 1,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [const Color(0xFFFFEFA1), const Color(0xFFFFEFA1).withValues(alpha: 0)],
              ),
            ),
          ),
          // 纵向光芒
          Container(
            width: 1,
            height: star.size * 4,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [const Color(0xFFFFEFA1), const Color(0xFFFFEFA1).withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      );
    } else {
      // 普通圆点星
      return Container(
        width: star.size,
        height: star.size,
        decoration: const BoxDecoration(
          color: Color(0xFFFFEFA1),
          shape: BoxShape.circle,
        ),
      );
    }
  }
}

enum _StarType { dot, cross }

class _StarModel {
  final double x;
  final double y;
  final double size;
  final _StarType type;
  final double twinkleSpeed;
  final double seed;
  final double opacityBase;

  _StarModel({
    required this.x,
    required this.y,
    required this.size,
    required this.type,
    required this.twinkleSpeed,
    required this.seed,
    required this.opacityBase,
  });
}
