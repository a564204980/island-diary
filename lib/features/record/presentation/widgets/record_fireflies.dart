import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 萤火虫氛围层
class FirefliesOverlay extends StatefulWidget {
  const FirefliesOverlay({super.key});

  @override
  State<FirefliesOverlay> createState() => _FirefliesOverlayState();
}

class _FirefliesOverlayState extends State<FirefliesOverlay>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
        });
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final topBarY = padding.top + 25;
    // 底部工具栏大致位置
    final bottomBarY = MediaQuery.of(context).size.height - padding.bottom - 45;

    return CustomPaint(
      painter: _FirefliesPainter(_elapsedSeconds, topBarY, bottomBarY),
    );
  }
}

class _FirefliesPainter extends CustomPainter {
  final double animationValue;
  final double topBarY;
  final double bottomBarY;

  // 增加到 70 个粒子，前 6 个负责底部彩蛋 (sp=2)
  static final List<Map<String, double>> _particles = List.generate(70, (i) {
    int spStatus = 0;
    if (i < 6) spStatus = 2; // 全部设为底部彩蛋

    final bool isBottomEgg = spStatus == 2;
    double seed(double k) => (i * k + 0.123) % 1.0;

    return {
      'x': seed(0.713),
      // 底部彩蛋强制初始在屏幕底端 (0.85 - 0.98 区域)，确保不从天而降
      'y': isBottomEgg ? 0.85 + seed(0.421) * 0.13 : seed(0.237),
      's': 1.0 + seed(0.33) * 1.5,
      'ph': i * 1.5,
      'vx': -30.0 + seed(0.887) * 60.0,
      'vy': -25.0 + seed(0.662) * 50.0,
      'wf': 0.4 + seed(0.12) * 1.5,
      'wa': 10.0 + seed(0.95) * 30.0,
      'sp': spStatus.toDouble(),
      'to': seed(0.55) * 25.0, // 独特的时间偏移
    };
  });

  _FirefliesPainter(this.animationValue, this.topBarY, this.bottomBarY);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < _particles.length; i++) {
      final config = _particles[i];
      final double spStatus = config['sp']!;
      final bool isSpecial = spStatus == 2.0;

      // 1. 呼吸闪烁
      final double opacityValue = (animationValue * 2.5 + config['ph']!);
      double baseOpacity = (0.1 + 0.6 * (0.5 + 0.5 * math.sin(opacityValue)))
          .clamp(0.0, 1.0);

      // 2. 运动控制实现
      double x, y;
      double finalOpacity = baseOpacity;

      if (isSpecial) {
        // 彩蛋逻辑：每 25 秒一个轮回
        const double cycle = 25.0;
        final double t = (animationValue + config['to']!) % cycle;
        final double startX = config['x']! * size.width;
        final double startY = config['y']! * size.height;

        // 分散的目标点：跨越屏幕 10% - 90%
        final double targetX = size.width * (0.1 + ((i * 0.17) % 0.8));
        final double targetY = bottomBarY + (i % 2 == 0 ? 3 : -3);

        const double swimTime = 7.0; // 游走时长
        final double anchorX = (startX + config['vx']! * swimTime) % size.width;
        double anchorY = (startY + config['vy']! * swimTime) % size.height;
        if (anchorY < 0) anchorY += size.height;

        if (t < swimTime) {
          x = (startX + config['vx']! * t) % size.width;
          y = (startY + config['vy']! * t) % size.height;
          if (y < 0) y += size.height;
        } else if (t < 10.5) {
          // 阶段 B: 减速接近
          final double p = (t - swimTime) / 3.5;
          final double easing = 1.0 - math.pow(1.0 - p, 3.0).toDouble();
          final double searchingWave = 15.0 * (1.0 - p) * math.sin(p * 10.0);
          x = anchorX + (targetX - anchorX) * easing + searchingWave;
          y = anchorY + (targetY - anchorY) * easing;
        } else if (t < 17.5) {
          // 阶段 C: 停靠休息
          x = targetX + 1.5 * math.sin(animationValue * 2.0);
          y = targetY + 1.0 * math.cos(animationValue * 1.5);
          baseOpacity = 0.8 + 0.2 * math.sin(animationValue * 3.0);
        } else {
          // 阶段 D: 平滑向下飞离并渐隐
          final double p = (t - 17.5) / 7.5;
          final double easing = (p * p).toDouble();
          x = targetX + (size.width * 0.3) * (i % 2 == 0 ? 1 : -1) * easing;
          y = targetY + (size.height * 0.15) * easing;
          baseOpacity *= (1.0 - p);
        }
        finalOpacity = baseOpacity;
      } else {
        // 普通漫游
        final double xLinear =
            config['x']! * size.width + config['vx']! * animationValue;
        final double yLinear =
            config['y']! * size.height + config['vy']! * animationValue;
        final double xWave =
            config['wa']! *
            math.sin(animationValue * config['wf']! + config['ph']!);

        x = (xLinear + xWave) % size.width;
        y = yLinear % size.height;
        if (y < 0) y = size.height + (y % size.height);

        final double altitudeFactor = (y / size.height).clamp(0.0, 1.0);
        finalOpacity = baseOpacity * math.pow(altitudeFactor, 2.5).toDouble();
      }

      if (finalOpacity < 0.01) continue;

      final double radius = config['s']!;
      paint.color = const Color(0xFFFFF9C4).withOpacity(finalOpacity);
      canvas.drawCircle(Offset(x, y), radius, paint);

      paint.color = const Color(0xFFFFF176).withOpacity(finalOpacity * 0.3);
      canvas.drawCircle(Offset(x, y), radius * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FirefliesPainter oldDelegate) => true;
}
