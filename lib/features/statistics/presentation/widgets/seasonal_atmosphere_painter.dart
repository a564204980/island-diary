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
      duration: const Duration(seconds: 10),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    _particles.clear();
    int count = widget.particleType == 'firefly' ? 15 : 25;
    if (widget.particleType == 'none') count = 0;

    for (int i = 0; i < count; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 2,
        speed: _random.nextDouble() * 0.003 + 0.001,
        angle: _random.nextDouble() * pi * 2,
        opacity: _random.nextDouble() * 0.5 + 0.2,
        type: widget.particleType,
      ));
    }
  }

  @override
  void didUpdateWidget(SeasonalAtmosphere oldWidget) {
    if (oldWidget.particleType != widget.particleType) {
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
            type: widget.particleType,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x, y, size, speed, angle, opacity;
  final String type;
  final Random _random = Random();

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.opacity,
    required this.type,
  });

  void update() {
    if (type == 'firefly') {
      // 萤火虫随机游走
      angle += (_random.nextDouble() - 0.5) * 0.1;
      x += cos(angle) * 0.0004;
      y += sin(angle) * 0.0004;
      opacity = (sin(DateTime.now().millisecondsSinceEpoch / 500 + x * 100) + 1.2) / 2.2 * 0.6;
    } else if (type == 'rain') {
        y += speed * 3;
        x += 0.001;
    } else {
      // 下落类
      y += speed;
      x += sin(y * 10) * 0.002; // 飘动效果
    }

    if (x > 1.0) x = 0;
    if (x < 0) x = 1.0;
    if (y > 1.0) y = 0;
    if (y < 0) y = 1.0;
  }
}

class _AtmospherePainter extends CustomPainter {
  final List<_Particle> particles;
  final bool isNight;
  final String type;

  _AtmospherePainter({required this.particles, required this.isNight, required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      final pos = Offset(p.x * size.width, p.y * size.height);
      
      if (type == 'flower') {
        paint.color = Colors.pink.withOpacity(p.opacity * (isNight ? 0.3 : 0.5));
        canvas.drawCircle(pos, p.size, paint);
      } else if (type == 'firefly') {
        paint.color = Colors.yellowAccent.withOpacity(p.opacity);
        canvas.drawCircle(pos, p.size * 1.5, paint);
        // 萤火辉光
        final glow = Paint()
          ..color = Colors.yellowAccent.withOpacity(p.opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(pos, p.size * 4, glow);
      } else if (type == 'leaf') {
        paint.color = Colors.orange.withOpacity(p.opacity * (isNight ? 0.4 : 0.6));
        canvas.drawOval(Rect.fromCenter(center: pos, width: p.size * 2, height: p.size), paint);
      } else if (type == 'frost' || type == 'none') {
        paint.color = Colors.white.withOpacity(p.opacity * (isNight ? 0.4 : 0.7));
        canvas.drawCircle(pos, p.size * 0.8, paint);
      } else if (type == 'rain') {
          paint.color = isNight ? Colors.white24 : Colors.blue.withOpacity(0.2);
          canvas.drawLine(pos, pos + const Offset(1, 15), paint..strokeWidth = 1.2);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
