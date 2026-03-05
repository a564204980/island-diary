import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SandBlowEffect extends StatefulWidget {
  final Widget child;
  final bool isDissolving;
  final VoidCallback? onAnimationComplete;

  const SandBlowEffect({
    super.key,
    required this.child,
    required this.isDissolving,
    this.onAnimationComplete,
  });

  @override
  State<SandBlowEffect> createState() => _SandBlowEffectState();
}

class _SandBlowEffectState extends State<SandBlowEffect>
    with SingleTickerProviderStateMixin {
  final GlobalKey _globalKey = GlobalKey();
  ui.Image? _image;
  late AnimationController _controller;
  List<Particle>? _particles;
  double _pixelRatio = 1.0;

  @override
  void initState() {
    super.initState();
    // 整个风沙消散的周期为2.5秒
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pixelRatio = MediaQuery.of(context).devicePixelRatio;
  }

  @override
  void didUpdateWidget(SandBlowEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDissolving && !oldWidget.isDissolving && _image == null) {
      _startDissolve();
    }
  }

  Future<void> _startDissolve() async {
    try {
      // 捕获当前的画面截图
      final boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: _pixelRatio);
      _generateParticles(image);

      setState(() {
        _image = image;
      });
      _controller.forward();
    } catch (e) {
      debugPrint("Failed to capture image: $e");
    }
  }

  void _generateParticles(ui.Image image) {
    final random = Random();
    final particles = <Particle>[];
    // 根据设备的像素密度缩放网格，确保碎片在10物理像素左右，以兼顾性能和美观
    final double gridSize = 10.0 * _pixelRatio;

    for (double y = 0; y < image.height; y += gridSize) {
      for (double x = 0; x < image.width; x += gridSize) {
        // 让风从右往左吹（右边的碎片先散开）
        // 归一化 X (0 表示左侧，1 表示右侧)
        final normalizedX = x / image.width;
        // sweepDelay 使得右边的粒子(normalizedX较大)获得较小的 delay
        final sweepDelay = (1.0 - normalizedX) * 0.4; // 0.0 ~ 0.4
        final randomDelay = random.nextDouble() * 0.2; // 增加一些微观上的错落随机感
        final delay = sweepDelay + randomDelay;

        particles.add(
          Particle(
            rect: Rect.fromLTWH(x, y, gridSize, gridSize),
            // 向左吹散，动能保持不变
            dx: -(random.nextDouble() * 400 * _pixelRatio + 150 * _pixelRatio),
            // 重大修改：y轴动能改成全负数，并且加大力度，让沙粒往“上方”飘走，形成左上角扩散
            dy: -(random.nextDouble() * 500 * _pixelRatio + 200 * _pixelRatio),
            delay: delay.clamp(0.0, 0.8),
            // 每个碎片的随机自转角度
            rotation: (random.nextDouble() - 0.5) * pi * 2,
          ),
        );
      }
    }
    _particles = particles;
  }

  @override
  void dispose() {
    _controller.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image != null && widget.isDissolving) {
      // 开始绘制粒子动画
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(
              _image!.width / _pixelRatio,
              _image!.height / _pixelRatio,
            ),
            painter: ParticlePainter(
              image: _image!,
              particles: _particles!,
              progress: _controller.value,
              pixelRatio: _pixelRatio,
            ),
          );
        },
      );
    }

    // 平时保持正常的组件树（通过 RepaintBoundary 可供之后截图）
    return RepaintBoundary(key: _globalKey, child: widget.child);
  }
}

class Particle {
  final Rect rect; // 在图片中的原始像素坐标系信息
  final double dx; // X方向吹走的总位移量
  final double dy; // Y方向吹走的总位移量
  final double delay; // 延迟起飞的时间(0~1)
  final double rotation; // 翻滚的最终角度

  Particle({
    required this.rect,
    required this.dx,
    required this.dy,
    required this.delay,
    required this.rotation,
  });
}

class ParticlePainter extends CustomPainter {
  final ui.Image image;
  final List<Particle> particles;
  final double progress;
  final double pixelRatio;

  ParticlePainter({
    required this.image,
    required this.particles,
    required this.progress,
    required this.pixelRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Canvas 使用的是逻辑像素，而截图(_image)是物理真实像素。
    // 因此我们需要通过缩放，使得所有绘制操作能直接匹配真实像素系。
    canvas.scale(1.0 / pixelRatio);

    final paint = Paint()..isAntiAlias = false; // 大量绘制关闭抗锯齿，获得更高性能

    for (final p in particles) {
      // 计算单个粒子的专属进度
      double particleProgress = 0.0;
      if (progress > p.delay) {
        particleProgress = (progress - p.delay) / (1.0 - p.delay);
      } else {
        particleProgress = 0.0;
      }

      if (particleProgress <= 0.0) {
        // 还没轮到它被吹走，原地老老实实呆着
        canvas.drawImageRect(image, p.rect, p.rect, paint);
        continue;
      }

      if (particleProgress >= 1.0) continue; // 完全消散了

      // 添加逐渐加速的缓动曲线，让沙粒有一种“被风带走”越来越快的感觉
      final easeProgress = particleProgress * particleProgress;

      // 逐渐消隐
      paint.color = Color.fromRGBO(255, 255, 255, 1.0 - particleProgress);

      final currentX = p.rect.left + p.dx * easeProgress;
      final currentY = p.rect.top + p.dy * easeProgress;

      canvas.save();
      // 将画布原点移到单个粒子的中心点，准备进行旋转
      canvas.translate(
        currentX + p.rect.width / 2,
        currentY + p.rect.height / 2,
      );
      canvas.rotate(p.rotation * particleProgress);

      final src = p.rect;
      final dst = Rect.fromLTWH(
        -p.rect.width / 2,
        -p.rect.height / 2,
        p.rect.width,
        p.rect.height,
      );

      canvas.drawImageRect(image, src, dst, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
