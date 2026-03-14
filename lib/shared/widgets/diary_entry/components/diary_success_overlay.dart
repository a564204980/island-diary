import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:island_diary/shared/widgets/sprite_animation.dart';
import 'package:flutter/foundation.dart';

enum ParticleType { circle, star, diamond, ring }

class DiarySuccessOverlay extends StatefulWidget {
  final VoidCallback onFinished;

  const DiarySuccessOverlay({super.key, required this.onFinished});

  @override
  State<DiarySuccessOverlay> createState() => _DiarySuccessOverlayState();
}

class _DiarySuccessOverlayState extends State<DiarySuccessOverlay>
    with TickerProviderStateMixin {
  late AnimationController _gatherController;
  late AnimationController _idleController;
  late List<ParticleModel> _particles;
  late int _atmosphericCount; // 氛围粒子随机数
  bool _showFinal = false;

  @override
  void initState() {
    super.initState();
    // 增加聚拢时长到 12.0 秒，营造细致的慢节奏
    _gatherController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );

    _gatherController.addListener(() {
      // 达到 83% 进度时（大球登场）
      if (_gatherController.value > 0.83 && !_showFinal) {
        setState(() {
          _showFinal = true;
        });
      }
    });

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _gatherController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    final rand = math.Random();
    _atmosphericCount = 20 + rand.nextInt(21); // 20 - 40 随机
    _particles = List.generate(
      2000,
      (index) => ParticleModel(size, index, _atmosphericCount),
    );
  }

  @override
  void dispose() {
    _gatherController.dispose();
    _idleController.dispose();
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
            // 0. 全屏渐变背景：保证开场纯净黑暗
            Positioned.fill(
              child:
                  Container(
                        color: const Color(0xFF020202).withOpacity(0.75),
                      ) // 调亮背景：0.96 -> 0.75
                      .animate()
                      .fadeIn(
                        duration: 1500.ms,
                        curve: Curves.easeOut,
                      ), // 仅保留淡入，移除后续呼吸脉冲
            ),

            // 0.5 能量汇聚预热光晕 (随粒子进度动态成长)
            _buildGatheringGlow(),

            // 1. 高性能粒子系统
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _gatherController,
                  _idleController,
                ]),
                builder: (context, child) {
                  return CustomPaint(
                    painter: ParticlePainter(
                      particles: _particles,
                      progress: _gatherController.value,
                      idleValue: _idleController.value,
                    ),
                  );
                },
              ),
            ),

            if (_showFinal)
              Center(
                child: Transform.translate(
                  offset: const Offset(0, -60), // 对齐中心修正至 -60
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildGreatBall(),
                      _buildCharacter(),
                      _buildSuccessText(),

                      // 点击提示
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatheringGlow() {
    return AnimatedBuilder(
      animation: _gatherController,
      builder: (context, child) {
        final progress = _gatherController.value;
        // 延后触发点：当粒子汇聚到大约 45% 时开始由 0 生长
        if (progress < 0.45 || progress > 0.95) return const SizedBox.shrink();

        double growth = 0;
        double opacity = 0;

        if (progress <= 0.83) {
          growth = (progress - 0.45) / (0.83 - 0.45);
          // 使用立方曲线确保初始从真正的 0 面积平滑变大
          growth = math.pow(growth.clamp(0.0, 1.0), 3.0).toDouble();
          opacity = (growth * 0.75).clamp(0.0, 0.75);
        } else {
          // 大球登场后淡出
          opacity = (1.0 - (progress - 0.83) / 0.12).clamp(0.0, 1.0) * 0.75;
          growth = 1.0;
        }

        final size = 260.0 * growth;

        return Center(
          child: Transform.translate(
            offset: const Offset(0, -55), // 粒子汇聚点再次微调向下
            child: Opacity(
              opacity: opacity,
              child: CustomPaint(
                size: Size(size, size),
                painter: GlowPainter(
                  color1: Colors.orangeAccent.withOpacity(0.8),
                  color2: Colors.amberAccent.withOpacity(0.4),
                  coreRadius: size * 0.3,
                  outerRadius: size * 0.5,
                  blur: (30 * growth).clamp(1.0, 30.0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreatBall() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container().animate().custom(
          duration: 1500.ms,
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            // 半径由 150 微调至 136：从 120 扩大到 136 并定格
            final outer = lerpDouble(120, 136, value)!;
            final core = lerpDouble(80, 100, value)!;
            final blur = lerpDouble(20, 22, value)!;

            return CustomPaint(
              size: const Size(400, 400),
              painter: GlowPainter(
                color1: Colors.orangeAccent.withOpacity(0.8),
                color2: Colors.amberAccent.withOpacity(0.5),
                coreRadius: core,
                outerRadius: outer,
                blur: blur,
              ),
            );
          },
        ),
        Container(
          width: 280,
          height: 280,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/great _ball.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    ).animate().fade(
      duration: 2000.ms,
      curve: Curves.easeInOut,
      begin: 0,
      end: 1.0, // 亮度拉满，且持久保持不消失
    );
  }

  Widget _buildCharacter() {
    return Container(
          width: 140,
          height: 140,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
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

class ParticleModel {
  late Offset startPoint;
  late double initialRadius;
  late double initialAngle;
  late double finalTargetRadius;
  late double size;
  late ParticleType type;
  late Color color;
  late double delay;
  late double swirlSpeed;
  late double rotationOffset;
  late double twinklePhase;
  late double twinkleSpeed;
  late bool isAtmospheric;
  late double atmospherePhaseOffset;
  late double breathPhase;
  late double breathSpeed;

  ParticleModel(Size screenSize, int index, int atmosphericCount) {
    final rand = math.Random();
    final double diagonal = math.sqrt(
      screenSize.width * screenSize.width +
          screenSize.height * screenSize.height,
    );
    initialRadius = diagonal * 0.55 + rand.nextDouble() * 100;
    initialAngle = rand.nextDouble() * math.pi * 2;

    // 根据动态传入的数量选出氛围粒子
    isAtmospheric = index < atmosphericCount;
    if (isAtmospheric) {
      finalTargetRadius = 145 + rand.nextDouble() * 40;
      size = 2.2 + rand.nextDouble() * 2.8; // 环境粒子个头大一圈
    } else {
      finalTargetRadius = rand.nextDouble() * 105;
      size = 1.2 + rand.nextDouble() * 2.4;
    }

    // 随机分配四种形状：圆形 40%，十字星 30%，晶钻 20%，星环 10%
    final shapeRand = rand.nextDouble();
    if (shapeRand < 0.4) {
      type = ParticleType.circle;
    } else if (shapeRand < 0.7) {
      type = ParticleType.star;
    } else if (shapeRand < 0.9) {
      type = ParticleType.diamond;
    } else {
      type = ParticleType.ring;
    }

    final colors = [
      const Color(0xFFFFECB3),
      const Color(0xFFFFD54F),
      const Color(0xFFFFB300),
      const Color(0xFFFFF9C4),
      Colors.white,
      const Color(0xFFFFE082),
    ];
    color = colors[rand.nextInt(colors.length)];

    final double randVal = rand.nextDouble();
    delay = math.pow(randVal, 0.5) * 0.72;

    swirlSpeed = (rand.nextDouble() - 0.5) * 5.0;
    rotationOffset = rand.nextDouble() * math.pi * 2;
    twinklePhase = rand.nextDouble() * math.pi * 2;
    twinkleSpeed = 2.5 + rand.nextDouble() * 3.5;
    atmospherePhaseOffset = rand.nextDouble() * math.pi * 2;
    breathPhase = rand.nextDouble() * math.pi * 2;
    breathSpeed = 3.0 + rand.nextDouble() * 2.5; // 呼吸频率
  }
}

class ParticlePainter extends CustomPainter {
  final List<ParticleModel> particles;
  final double progress;
  final double idleValue;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.idleValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2 - 55);
    final paint = Paint();

    for (var p in particles) {
      const double travelDuration = 0.25;
      double localProgress = (progress - p.delay) / travelDuration;

      if (localProgress < 0) continue;
      final bool reachedCenter = localProgress >= 1.0;
      final double effectiveLP = reachedCenter ? 1.0 : localProgress;

      double alpha = 1.0;
      if (localProgress < 0.2) {
        alpha = localProgress / 0.2;
      }

      final curveValue = math.pow(effectiveLP, 2.5).toDouble();
      final currentRadius = lerpDouble(
        p.initialRadius,
        p.finalTargetRadius,
        curveValue,
      )!;

      double jitterX = 0;
      double jitterY = 0;
      if (reachedCenter) {
        final double jitterAngle = p.rotationOffset + progress * 2;
        jitterX = math.cos(jitterAngle) * (p.size * 0.5);
        jitterY = math.sin(jitterAngle) * (p.size * 0.5);
      }

      double orbitX = 0;
      double orbitY = 0;
      if (reachedCenter && p.isAtmospheric) {
        // 环境粒子驻留后的缓慢绕场漂浮感 (由 idleValue 驱动)
        // 使用整数倍率 (2.0) 确保 idleValue 从 1.0 回到 0.0 时相位平滑衔接
        double orbitAngle =
            p.atmospherePhaseOffset + idleValue * math.pi * 2 * 2.0;
        orbitX = math.cos(orbitAngle) * 8.0;
        orbitY = math.sin(orbitAngle) * 8.0;
      }

      final finalX =
          center.dx +
          math.cos(p.initialAngle) * currentRadius +
          jitterX +
          orbitX;
      final finalY =
          center.dy +
          math.sin(p.initialAngle) * currentRadius +
          jitterY +
          orbitY;

      double globalFade = 1.0;
      if (progress > 0.85) {
        // 氛围粒子在大球出现后坚守，不参与快速退场
        globalFade = p.isAtmospheric
            ? 1.0
            : (1.0 - (progress - 0.85) / 0.15).clamp(0.0, 1.0);
      }

      // --- 分阶段动效强度控制 (让汇聚阶段更安静，大球出现后再灵动) ---
      double dynamicIntensity = 0.15;
      if (progress > 0.82) {
        dynamicIntensity = (0.15 + (progress - 0.82) / 0.13 * 0.85).clamp(
          0.15,
          1.0,
        );
      }

      double twinkle = 1.0;
      if (reachedCenter) {
        if (p.isAtmospheric) {
          // 氛围粒子慢速眨眼，眨动深度受当前动感强度控制 (由循环的 idleValue 驱动以保持持久)
          double twinkleDepth = 0.4 * dynamicIntensity;
          double twinkleVal = idleValue * math.pi * 2 * 6.0 + p.twinklePhase;
          twinkle = (1.0 - twinkleDepth) + math.sin(twinkleVal) * twinkleDepth;
        } else {
          // 核心区域细密快闪 (随汇聚结束而停止)
          twinkle =
              0.65 +
              math.sin(progress * 60.0 * p.twinkleSpeed + p.twinklePhase) *
                  0.35;
        }
      }

      final finalAlpha = (alpha * globalFade * twinkle).clamp(0.0, 1.0);
      paint.color = p.color.withOpacity(finalAlpha);

      double finalSize = p.size;
      if (p.isAtmospheric && reachedCenter) {
        // 呼吸幅度下调：0.8 -> 0.35，使其更优雅内敛
        double breathRange = 0.35 * dynamicIntensity;
        // 使用整数倍率 (4.0) 确保循环无跳变
        double breathVal = idleValue * math.pi * 2 * 4.0 + p.breathPhase;
        finalSize = p.size * (1.0 + math.sin(breathVal) * breathRange);

        // --- 环境粒子独立光晕优化 (更紧致、更通透) ---
        final haloPaint = Paint()
          ..color = p.color.withOpacity(finalAlpha * 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(finalX, finalY), finalSize * 2.5, haloPaint);
      }

      if (p.type == ParticleType.circle) {
        canvas.drawCircle(Offset(finalX, finalY), finalSize, paint);
        paint.color = Colors.white.withOpacity(finalAlpha * 0.5);
        canvas.drawCircle(Offset(finalX, finalY), finalSize * 0.5, paint);
      } else if (p.type == ParticleType.star) {
        final double starSize = finalSize * 1.5;
        final path = Path();
        path.moveTo(finalX, finalY - starSize);
        path.quadraticBezierTo(finalX, finalY, finalX + starSize, finalY);
        path.quadraticBezierTo(finalX, finalY, finalX, finalY + starSize);
        path.quadraticBezierTo(finalX, finalY, finalX - starSize, finalY);
        path.quadraticBezierTo(finalX, finalY, finalX, finalY - starSize);
        canvas.drawPath(path, paint);
      } else if (p.type == ParticleType.diamond) {
        // 晶钻：旋转 45 度的菱形
        final double dSize = finalSize * 1.3;
        final path = Path();
        path.moveTo(finalX, finalY - dSize); // 顶
        path.lineTo(finalX + dSize, finalY); // 右
        path.lineTo(finalX, finalY + dSize); // 底
        path.lineTo(finalX - dSize, finalY); // 左
        path.close();
        canvas.drawPath(path, paint);
        // 增加中心高光
        paint.color = Colors.white.withOpacity(finalAlpha * 0.5);
        canvas.drawCircle(Offset(finalX, finalY), dSize * 0.3, paint);
      } else if (p.type == ParticleType.ring) {
        // 星环：空心圆
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 0.8;
        canvas.drawCircle(Offset(finalX, finalY), finalSize * 1.2, paint);
        // 恢复实心模式供后续绘制使用
        paint.style = PaintingStyle.fill;
      }

      if (finalSize > 2.8 && localProgress < 0.92) {
        paint.color = p.color.withOpacity(finalAlpha * 0.2);
        canvas.drawCircle(Offset(finalX, finalY), finalSize * 3.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.idleValue != idleValue;
}

class GlowPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double coreRadius;
  final double outerRadius;
  final double blur;

  GlowPainter({
    required this.color1,
    required this.color2,
    required this.coreRadius,
    required this.outerRadius,
    required this.blur,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    paint.shader = RadialGradient(
      colors: [color1, color1.withOpacity(0)],
      stops: const [0.5, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: coreRadius));
    canvas.drawCircle(center, coreRadius, paint);

    paint.shader = RadialGradient(
      colors: [color2.withOpacity(0.6), color2.withOpacity(0)],
      stops: const [0.3, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius, paint);
  }

  @override
  bool shouldRepaint(covariant GlowPainter oldDelegate) =>
      oldDelegate.coreRadius != coreRadius ||
      oldDelegate.outerRadius != outerRadius ||
      oldDelegate.blur != blur;
}
