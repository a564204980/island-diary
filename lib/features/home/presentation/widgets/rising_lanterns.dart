import 'dart:math' as math;
import 'package:flutter/material.dart';

class RisingLanterns extends StatefulWidget {
  final int count;
  final bool isForeground;
  final bool shouldAnimate;

  const RisingLanterns({
    super.key,
    this.count = 8,
    this.isForeground = false,
    this.shouldAnimate = true,
  });

  @override
  State<RisingLanterns> createState() => _RisingLanternsState();
}

class _RisingLanternsState extends State<RisingLanterns>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_LanternModel> _lanterns;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _initLanterns();
  }

  void _initLanterns() {
    _lanterns = List.generate(widget.count, (index) {
      return _generateLantern(initial: true);
    });
  }

  _LanternModel _generateLantern({bool initial = false}) {
    // 进一步拉大远近差距
    // 背景层 depth 范围 0.15 - 0.4 (更远、更小)
    // 前景层 depth 范围 0.7 - 1.2 (更近、更大)
    double depth = widget.isForeground
        ? 0.7 + _random.nextDouble() * 0.5
        : 0.15 + _random.nextDouble() * 0.25;

    // 根据深度计算尺寸和速度
    double baseSize = widget.isForeground ? 65.0 : 35.0;
    double size = baseSize * depth;
    double speed = (1.2 + _random.nextDouble() * 1.8) * depth; // 显著拉开速度差

    // 随机选择图片路径
    final List<String> lanternImages = [
      'assets/images/icons/5/denglong1.png',
      'assets/images/icons/5/denglong2.png',
      'assets/images/icons/5/denglong3.png',
      'assets/images/icons/5/denglong4.png',
      'assets/images/icons/5/denglong5.png',
      'assets/images/icons/5/denglong6.png',
      'assets/images/icons/5/denglong7.png',
      'assets/images/icons/5/denglong8.png',
      'assets/images/icons/5/denglong9.png',
    ];
    String imagePath = lanternImages[_random.nextInt(lanternImages.length)];

    return _LanternModel(
      x: _random.nextDouble(),
      // 如果是初始化，随机分布高度；否则从底部出现
      y: initial ? _random.nextDouble() * 1.5 : 1.2,
      size: size,
      speed: speed / 1000,
      opacity: (0.3 + (depth * 0.7)).clamp(0.0, 1.0), // 确保透明度不超出 1.0
      swingAmplitude: 10.0 + _random.nextDouble() * 20.0,
      swingSpeed: 0.0004 + _random.nextDouble() * 0.0006, // 显著降低摆动频率 (约 6-15秒一个来回)
      imagePath: imagePath,
      seed: _random.nextDouble() * math.pi * 2,
    );
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

        for (var lantern in _lanterns) {
          lantern.y -= lantern.speed;
          // 如果飞出屏幕顶部，重新从底部生成
          if (lantern.y < -0.2) {
            int index = _lanterns.indexOf(lantern);
            _lanterns[index] = _generateLantern();
          }
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: _lanterns.map((lantern) {
                // 使用绝对时间计算摆动，彻底解决周期切换时的抽动
                double swing = math.sin(time * lantern.swingSpeed + lantern.seed) * lantern.swingAmplitude;
                
                return Positioned(
                  left: lantern.x * constraints.maxWidth + swing,
                  top: lantern.y * constraints.maxHeight,
                  child: Opacity(
                    opacity: lantern.opacity,
                    child: Image.asset(
                      lantern.imagePath,
                      width: lantern.size,
                      height: lantern.size,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _LanternModel {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final double swingAmplitude;
  final double swingSpeed;
  final String imagePath;
  final double seed;

  _LanternModel({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.swingAmplitude,
    required this.swingSpeed,
    required this.imagePath,
    required this.seed,
  });
}
