import 'dart:math';
import 'package:flutter/material.dart';

class SeasonalAtmosphere extends StatefulWidget {
  final String particleType; // flower, firefly, leaf, frost, rain
  final bool isNight;

  const SeasonalAtmosphere({
    super.key,
    required this.particleType,
    this.isNight = false,
  });

  @override
  State<SeasonalAtmosphere> createState() => _SeasonalAtmosphereState();
}

class _SeasonalAtmosphereState extends State<SeasonalAtmosphere> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    _particles.clear();
    if (widget.particleType == 'none') return;

    // 基础季节粒子数量（优质感重于数量）
    int seasonalCount = 18;
    
    // 1. 初始化季节性粒子
    for (int i = 0; i < seasonalCount; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        baseSize: _random.nextDouble() * 2 + 1.5,
        speed: _random.nextDouble() * 0.002 + 0.0005,
        depth: _random.nextDouble(), // 0.0 (远) -> 1.0 (近)
        type: widget.particleType,
      ));
    }

    // 2. 夜间模式额外追加 6 个萤火虫（常驻灵感）
    if (widget.isNight) {
      for (int i = 0; i < 6; i++) {
        _particles.add(_Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          baseSize: _random.nextDouble() * 1.5 + 1.5,
          speed: _random.nextDouble() * 0.0015 + 0.0008,
          depth: _random.nextDouble() * 0.8 + 0.2,
          type: 'firefly',
        ));
      }
    }
  }

  @override
  void didUpdateWidget(SeasonalAtmosphere oldWidget) {
    if (oldWidget.particleType != widget.particleType || oldWidget.isNight != widget.isNight) {
      _initParticles();
    }
    super.didUpdateWidget(oldWidget);
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
        for (var p in _particles) {
          p.update();
        }
        return CustomPaint(
          painter: _AtmospherePainter(
            particles: _particles,
            isNight: widget.isNight,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x, y, baseSize, speed, depth;
  final String type;
  final Random _random = Random();
  double _angle;
  final double _wavePhase;

  _Particle({
    required this.x,
    required this.y,
    required this.baseSize,
    required this.speed,
    required this.depth,
    required this.type,
  }) : _angle = Random().nextDouble() * pi * 2,
       _wavePhase = Random().nextDouble() * pi * 2;

  void update() {
    // 根据深度动态调节速度 (远处慢，近处快)
    final double depthSpeedMult = 0.4 + (depth * 1.6);
    final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;

    if (type == 'firefly') {
      // 萤火虫：随机游走 + 深度漂浮
      _angle += (_random.nextDouble() - 0.5) * 0.15;
      x += cos(_angle) * 0.0008 * depthSpeedMult;
      y += sin(_angle) * 0.0008 * depthSpeedMult;
    } else if (type == 'rain') {
      y += speed * 4.5 * depthSpeedMult;
      x += 0.0015 * depthSpeedMult;
    } else {
      // 通用漂浮类 (花/叶/雪)
      y += speed * depthSpeedMult;
      // 结合位置与时间的湍流感
      x += sin(time + _wavePhase + y * 5) * 0.0015 * (1.0 - depth * 0.5);
    }

    // 边缘循环控制 (带边距缓冲)
    const margin = 0.15;
    if (x > 1.0 + margin) x = -margin;
    if (x < -margin) x = 1.0 + margin;
    if (y > 1.0 + margin) y = -margin;
    if (y < -margin) y = 1.0 + margin;
  }
}

class _AtmospherePainter extends CustomPainter {
  final List<_Particle> particles;
  final bool isNight;

  _AtmospherePainter({required this.particles, required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    
    // 按深度降序排列（确保真实的层叠透视）
    final sortedParticles = List<_Particle>.from(particles)
      ..sort((a, b) => a.depth.compareTo(b.depth));

    for (var p in sortedParticles) {
      final double depth = p.depth;
      final pos = Offset(p.x * size.width, p.y * size.height);
      
      // 核心动态参数：虚化大小与呼吸频率
      final double currentSize = p.baseSize * (1.1 + depth * 3.5); 
      final double pulse = (sin(DateTime.now().millisecondsSinceEpoch / (700 + depth * 300).toInt() + p.x * 20) + 1.0) / 2.0;
      final double opacity = (0.22 + depth * 0.28) * (0.6 + 0.4 * pulse);
      
      Color mainColor;
      switch (p.type) {
        case 'flower': mainColor = const Color(0xFFFFC2D1); break; // 柔和夜楼粉
        case 'firefly': mainColor = const Color(0xFFFFD54F); break;
        case 'leaf': mainColor = const Color(0xFFFFB347); break;
        case 'rain': mainColor = isNight ? Colors.white30 : Colors.blue.withOpacity(0.3); break;
        default: mainColor = Colors.white;
      }

      if (p.type == 'rain') {
        paint.color = mainColor.withOpacity(opacity);
        canvas.drawLine(pos, pos + Offset(1.5, 20 * depth + 5), paint..strokeWidth = 0.8 + depth);
      } else {
        // 关键视觉：博凯虚化渲染
        final double blurSigma = depth * 11.0 + 0.8; 
        
        paint.color = mainColor.withOpacity(opacity);
        if (depth > 0.7) {
          // 近景：径向渐变模拟虚化圆环
          paint.shader = RadialGradient(
            colors: [
              mainColor.withOpacity(opacity * 1.4), 
              mainColor.withOpacity(opacity * 0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromCircle(center: pos, radius: currentSize * 2.2));
          canvas.drawCircle(pos, currentSize * 2.2, paint);
          paint.shader = null;
        } else {
          // 中远景：带模糊的柔和点
          paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
          canvas.drawCircle(pos, currentSize, paint);
          paint.maskFilter = null;
        }
        
        // 萤火特有渲染：金色晕染层
        if (p.type == 'firefly') {
          canvas.drawCircle(pos, currentSize * 4.5, Paint()
            ..color = mainColor.withOpacity(opacity * 0.18)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * depth + 6));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) => true;
}
