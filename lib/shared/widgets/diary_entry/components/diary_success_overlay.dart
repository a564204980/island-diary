import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:island_diary/shared/widgets/sprite_animation.dart';

class DiarySuccessOverlay extends StatefulWidget {
  final VoidCallback onFinished;

  const DiarySuccessOverlay({super.key, required this.onFinished});

  @override
  State<DiarySuccessOverlay> createState() => _DiarySuccessOverlayState();
}

class _DiarySuccessOverlayState extends State<DiarySuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _gatherController;
  late List<ParticleModel> _particles;
  bool _showFinal = false;

  @override
  void initState() {
    super.initState();
    // 增加聚拢时长到 20.0 秒，营造极细腻的慢节奏
    _gatherController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 15000),
    );

    _gatherController.addListener(() {
      // 提前 2 秒左右出场：将阈值从 0.95 降低到约 0.83 (15s * 0.83 ≈ 12.5s)
      if (_gatherController.value > 0.83 && !_showFinal) {
        setState(() {
          _showFinal = true;
        });
      }
    });

    // 直接启动粒子动画
    _gatherController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    // 数量拉到 2000 个，营造如烟似幻的星河汇聚感
    _particles = List.generate(2000, (index) => ParticleModel(size));
  }

  @override
  void dispose() {
    _gatherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showFinal ? widget.onFinished : null,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 0. 全屏渐变背景
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 1000.ms),
            ),

            // 1. 高性能粒子系统：2000 颗星辰汇聚
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _gatherController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ParticlePainter(
                      particles: _particles,
                      progress: _gatherController.value,
                    ),
                  );
                },
              ),
            ),

            // 2. 最终结果：使用 great_ball.png 作为背景
            if (_showFinal)
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildGreatBall(),
                    _buildCharacter(),
                    _buildSuccessText(),

                    // 点击任意处结束提示
                    Positioned(
                      bottom: -150,
                      child:
                          const Text(
                                '点击任意处继续',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  letterSpacing: 2,
                                ),
                              )
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .fadeIn(duration: 1000.ms)
                              .fadeOut(delay: 500.ms, duration: 1000.ms),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 移除 _buildFinalFlash，它是导致“方形闪烁”的主要嫌疑点，且现在不需要这种强烈冲击

  Widget _buildGreatBall() {
    return Container(
      width: 280,
      height: 280,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/great _ball.png'),
          fit: BoxFit.contain,
        ),
      ),
    ).animate().fadeIn(duration: 2000.ms, curve: Curves.easeInOut);
  }

  Widget _buildCharacter() {
    return Container(
          width: 140,
          height: 140,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 发光底盘
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 50,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                ),
                // 透明序列帧动画
                const SpriteAnimation(
                  assetPath: 'assets/images/emoji/weixiao.png',
                  frameCount: 9,
                  size: 80,
                  duration: Duration(milliseconds: 1200),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 500.ms, duration: 2500.ms, curve: Curves.easeInOut)
        .then(delay: 500.ms)
        .custom(
          duration: 3000.ms,
          builder: (context, val, child) => Transform.translate(
            offset: Offset(0, math.sin(val * math.pi * 2) * 8),
            child: child,
          ),
        );
  }

  Widget _buildSuccessText() {
    return Positioned(
      bottom: -110,
      child:
          Text(
                '已存入记忆瓶中',
                style: TextStyle(
                  fontFamily: 'FZKai',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3.0,
                  shadows: [
                    Shadow(color: Color(0xFF039BE5), blurRadius: 25),
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              )
              .animate()
              .hide()
              .show(delay: 600.ms)
              .fadeIn(duration: 800.ms)
              .slideY(begin: 0.6, end: 0.0),
    );
  }
}

/// 粒子模型
class ParticleModel {
  late Offset startPoint; // 仅保留作为兼容或参考，逻辑改用极坐标
  late double initialRadius;
  late double initialAngle;
  late double finalTargetRadius; // 目标半径，用于形成“一大坨”的面感
  late double size;
  late Color color;
  late double delay;
  late double swirlSpeed;
  late double rotationOffset;
  late double fadeInOffset; // 入场淡入进度

  ParticleModel(Size screenSize) {
    final rand = math.Random();

    // 真正的对角线外入场：确保所有粒子百分百从屏幕外汇聚，解决方向不对的问题
    final double diagonal = math.sqrt(
      screenSize.width * screenSize.width +
          screenSize.height * screenSize.height,
    );
    initialRadius = diagonal * 0.55 + rand.nextDouble() * 100;
    initialAngle = rand.nextDouble() * math.pi * 2;
    // 缩小汇聚面积：目标半径分布从 135 缩减至 105
    finalTargetRadius = rand.nextDouble() * 105;

    // 兼容位置计算
    startPoint = Offset(
      screenSize.width / 2 + math.cos(initialAngle) * initialRadius,
      screenSize.height / 2 + math.sin(initialAngle) * initialRadius,
    );

    size = 1.2 + rand.nextDouble() * 2.4;

    final colors = [
      Colors.white,
      Colors.cyanAccent,
      Colors.lightBlueAccent,
      const Color(0xFFB2EBF2),
      const Color(0xFFE1F5FE),
      const Color(0xFFB39DDB), // 浅紫
      const Color(0xFF90CAF9),
    ];
    color = colors[rand.nextInt(colors.length)];

    // 修复终场不消失：确保最晚的一颗星星也有足够时间在 15s 结束前飞到终点
    // 设置最大延迟为 0.7 (即 70% 进度处)，预留 25% 的旅行时间 + 5% 的缓冲
    final double randVal = rand.nextDouble();
    delay = math.pow(randVal, 0.5) * 0.72;

    swirlSpeed = (rand.nextDouble() - 0.5) * 5.0; // 螺旋旋转强度
    rotationOffset = rand.nextDouble() * math.pi * 2;
    fadeInOffset = 0.05 + rand.nextDouble() * 0.1; // 极速淡入，避免硬出现
  }
}

class ParticlePainter extends CustomPainter {
  final List<ParticleModel> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();

    // 1. 背景微光晕：营造深邃的空气感
    final double glowAlpha = (progress * 0.15).clamp(0.0, 0.15);
    paint.shader = RadialGradient(
      colors: [Colors.white.withOpacity(glowAlpha), Colors.transparent],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    for (var p in particles) {
      // 3. 独立汇聚逻辑：粒子出现后即开始独立的向心旅行
      // 不再受总时长 (1.0) 限制，设定每颗粒子从出现到汇聚核心仅需约总进度的 20% 时间 (约 3s)
      const double travelDuration = 0.25;
      double localProgress = (progress - p.delay) / travelDuration;

      if (localProgress < 0) continue;
      // 允许 localProgress >= 1.0，使其在中心停留聚集
      final bool reachedCenter = localProgress >= 1.0;
      final double effectiveLP = reachedCenter ? 1.0 : localProgress;

      // 1. 入场渐显动画
      double alpha = 1.0;
      if (localProgress < 0.2) {
        alpha = localProgress / 0.2;
      }

      // 2. 物理重构：极坐标向心投影
      final curveValue = math.pow(effectiveLP, 2.5).toDouble();

      // 核心修改：不再汇聚到点 0，而是汇聚到设定的目标半径，形成一个充满气泡的汇聚面
      final currentRadius = lerpDouble(
        p.initialRadius,
        p.finalTargetRadius,
        curveValue,
      )!;

      // 增加灵动的微小抖动
      double jitterX = 0;
      double jitterY = 0;
      if (reachedCenter) {
        final double jitterAngle = p.rotationOffset + progress * 2;
        jitterX = math.cos(jitterAngle) * (p.size * 0.5);
        jitterY = math.sin(jitterAngle) * (p.size * 0.5);
      }

      final finalX =
          center.dx + math.cos(p.initialAngle) * currentRadius + jitterX;
      final finalY =
          center.dy + math.sin(p.initialAngle) * currentRadius + jitterY;

      // 3. 样式渲染
      // 全局退场逻辑：配合气泡提前出场，淡出也相应提前
      double globalFade = 1.0;
      if (progress > 0.85) {
        globalFade = (1.0 - (progress - 0.85) / 0.15).clamp(0.0, 1.0);
      }

      final finalAlpha = (alpha * globalFade).clamp(0.0, 1.0);

      paint.color = p.color.withOpacity(finalAlpha);
      canvas.drawCircle(Offset(finalX, finalY), p.size, paint);

      // 中心大粒子光晕：适当保留轻微光晕以增加美感，但不使用模糊滤镜
      if (p.size > 3.2 && localProgress < 0.92) {
        paint.color = p.color.withOpacity(finalAlpha * 0.25);
        canvas.drawCircle(Offset(finalX, finalY), p.size * 2.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
