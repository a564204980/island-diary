import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 一个带有动态滚动小太阳和棋盘格网格的背景组件
class ScrollingSunBackground extends StatefulWidget {
  const ScrollingSunBackground({super.key});

  @override
  State<ScrollingSunBackground> createState() => _ScrollingSunBackgroundState();
}

class _ScrollingSunBackgroundState extends State<ScrollingSunBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ui.Image? _sunImage;

  @override
  void initState() {
    super.initState();
    // 设置循环动画，持续时间可根据需要调整滚动速度
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final data = await rootBundle.load('assets/images/icons/sun.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _sunImage = frame.image;
        });
      }
    } catch (e) {
      debugPrint('Failed to load sun image: $e');
    }
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
          painter: _SunBackgroundPainter(
            sunImage: _sunImage,
            animationValue: _controller.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _SunBackgroundPainter extends CustomPainter {
  final ui.Image? sunImage;
  final double animationValue;

  _SunBackgroundPainter({this.sunImage, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 绘制棋盘格背景
    const double squareSize = 60.0;
    final Paint lightPaint = Paint()..color = const Color(0xFFF3E9C9);
    final Paint darkPaint = Paint()..color = const Color(0xFFE9DDB3);

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final bool isDark = ((x / squareSize).floor() + (y / squareSize).floor()) % 2 != 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isDark ? darkPaint : lightPaint,
        );
      }
    }

    if (sunImage == null) return;

    // 2. 绘制滚动的太阳图标
    const double spacing = 180.0;
    const double iconSize = 48.0;
    
    // 计算当前的偏移量 (从右上到左下: x 减小, y 增大)
    final double baseOffsetX = -animationValue * spacing;
    final double baseOffsetY = animationValue * spacing;

    final Paint sunPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);

    // 覆盖整个屏幕及其边缘
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        // 1. 基础网格索引
        final double ix = x / spacing;
        final double iy = y / spacing;
        
        // 2. 引入确定性的参差不齐感 (Deterministic Jitter)
        // 使用正弦函数根据坐标生成偏移，确保同一个位置的太阳偏移量一致，从而动画滚动时不会闪烁
        final double jitterX = math.sin(ix * 1.5 + iy * 2.1) * (spacing * 0.25);
        final double jitterY = math.cos(ix * 0.8 + iy * 1.7) * (spacing * 0.25);

        // 3. 计算最终位置
        double drawX = x + baseOffsetX + jitterX;
        double drawY = y + baseOffsetY + jitterY;
        
        // 4. 保证循环显示 (使用取模，增加缓冲区确保平滑)
        final double totalW = size.width + spacing * 2;
        final double totalH = size.height + spacing * 2;
        drawX = (drawX % totalW) - spacing;
        drawY = (drawY % totalH) - spacing;

        canvas.drawImageRect(
          sunImage!,
          Rect.fromLTWH(0, 0, sunImage!.width.toDouble(), sunImage!.height.toDouble()),
          Rect.fromLTWH(drawX, drawY, iconSize, iconSize),
          sunPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SunBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.sunImage != sunImage;
  }
}
