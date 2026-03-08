import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/sprite_animation.dart';

/// 底部导航栏中心的“心情精灵”按钮
/// 独立管理：未来可根据心情状态动态切换不同表情序列帧，并触发不同对话。
class CenterMoodButton extends StatefulWidget {
  final double radius;
  final VoidCallback onTap;

  const CenterMoodButton({
    super.key,
    required this.radius,
    required this.onTap,
  });

  @override
  State<CenterMoodButton> createState() => _CenterMoodButtonState();
}

class _CenterMoodButtonState extends State<CenterMoodButton> {
  // TODO: 这里后续可以接入 UserState 或 MoodProvider，
  // 监听用户心情变化，然后动态分配不同的精灵图路径和帧参数。
  final String _currentAvatarPath = 'assets/images/emoji/weixiao.png';
  final int _frameCount = 9;
  final Duration _animationDuration = const Duration(milliseconds: 800);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. 最外层的呼吸光圈层 (Flutter Animate)
          _buildOuterGlow(),

          // 2. 粒子碎光层 (CustomPainter)
          _buildParticles(),

          // 3. 核心按钮主体
          _buildMainButton(),
        ],
      ),
    );
  }

  /// 构建最外层的多个扩散/呼吸光圈
  Widget _buildOuterGlow() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 大光圈 1
        Container(
              width: widget.radius * 2.6,
              height: widget.radius * 2.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD97D).withAlpha(100),
                    const Color(0xFFFFD97D).withAlpha(0),
                  ],
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.1, 1.1),
              duration: 2000.ms,
              curve: Curves.easeInOut,
            )
            .fadeOut(duration: 2000.ms),

        // 稍微小一点、实一点的光圈 2
        Container(
              width: widget.radius * 2.2,
              height: widget.radius * 2.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE5A0).withAlpha(60),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.05, 1.05),
              duration: 1500.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }

  /// 构建随机粒子碎光
  Widget _buildParticles() {
    return SizedBox(
      width: widget.radius * 3,
      height: widget.radius * 3,
      child: RepaintBoundary(
        child: _MoodAuraParticles(color: const Color(0xFFFFD97D)),
      ),
    );
  }

  /// 核心按钮组件（复用之前的样式并微调）
  Widget _buildMainButton() {
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF0C0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD97D).withAlpha(180),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(
        child: SpriteAnimation(
          key: ValueKey(_currentAvatarPath),
          assetPath: _currentAvatarPath,
          frameCount: _frameCount,
          duration: _animationDuration,
          size: widget.radius * 1.5,
        ),
      ),
    );
  }
}

/// 自定义粒子绘制器，实现碎光效果
class _MoodAuraParticles extends StatefulWidget {
  final Color color;
  const _MoodAuraParticles({required this.color});

  @override
  State<_MoodAuraParticles> createState() => _MoodAuraParticlesState();
}

class _MoodAuraParticlesState extends State<_MoodAuraParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final int _particleCount = 12;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: 2.seconds)
      ..repeat();
    // 初始化粒子
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_Particle());
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
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            baseColor: widget.color,
          ),
        );
      },
    );
  }
}

class _Particle {
  late double angle;
  late double distance;
  late double size;
  late double speed;

  _Particle() {
    reset();
  }

  void reset() {
    final random = math.Random();
    angle = random.nextDouble() * 2 * math.pi;
    distance = 30.0 + random.nextDouble() * 40.0;
    size = 1.0 + random.nextDouble() * 3.0;
    speed = 0.5 + random.nextDouble() * 1.5;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color baseColor;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = baseColor;

    for (var particle in particles) {
      // 随时间旋转和轻微位移
      final currentAngle = particle.angle + (progress * particle.speed * 0.5);
      // 呼吸式距离变化
      final currentDist =
          particle.distance + math.sin(progress * math.pi * 2) * 5;

      final offset = Offset(
        center.dx + math.cos(currentAngle) * currentDist,
        center.dy + math.sin(currentAngle) * currentDist,
      );

      // 闪烁效果 (Alpha 随进度变化)
      final opacity =
          (math.sin(progress * math.pi * 2 + particle.angle) + 1) / 2;
      paint.color = baseColor.withOpacity(opacity * 0.8);

      canvas.drawCircle(offset, particle.size, paint);
      // 增加一个小一点的光晕
      paint.color = baseColor.withOpacity(opacity * 0.3);
      canvas.drawCircle(offset, particle.size * 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
