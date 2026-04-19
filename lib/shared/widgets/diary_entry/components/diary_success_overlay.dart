import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';

enum ParticleType { circle, star, diamond, ring }

class DiarySuccessOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  final MascotAchievement achievement;

  const DiarySuccessOverlay({
    super.key,
    required this.onFinished,
    required this.achievement,
  });

  @override
  State<DiarySuccessOverlay> createState() => _DiarySuccessOverlayState();
}

class _DiarySuccessOverlayState extends State<DiarySuccessOverlay>
    with TickerProviderStateMixin {
  late AnimationController _gatherController;
  late AnimationController _idleController;
  late List<ParticleModel> _particles;
  late int _atmosphericCount;
  bool _showFinal = false;

  @override
  void initState() {
    super.initState();
    _gatherController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );
    _gatherController.addListener(() {
      if (_gatherController.value > 0.85 && !_showFinal) {
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
    _atmosphericCount = 30;
    _particles = List.generate(
      400,
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
            Positioned.fill(
              child: Container(
                color: const Color(0xFF020202).withValues(alpha: 0.75),
              ).animate().fadeIn(duration: 1500.ms),
            ),
            _buildGatheringGlow(),
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
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _buildGreatBall(),
                    _buildRewardDisplay(),
                    Positioned(
                      top: 320,
                      child:
                          const Text(
                                '点击任意处继续',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  letterSpacing: 2,
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
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

  Widget _buildGatheringGlow() {
    return AnimatedBuilder(
      animation: _gatherController,
      builder: (context, child) {
        final progress = _gatherController.value;
        if (progress < 0.05 || progress > 0.95) {
          return const SizedBox.shrink();
        }
        double growth = math
            .pow((progress - 0.05).clamp(0.0, 0.78) / 0.78, 3.0)
            .toDouble();
        double opacity = 0.0;
        if (progress <= 0.83) {
          opacity = growth * 0.75;
        } else {
          opacity = (1.0 - (progress - 0.83) / 0.12) * 0.75;
        }
        final size = 260.0 * growth;
        return Center(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: CustomPaint(
              size: Size(size, size),
              painter: GlowPainter(
                color1: Colors.orangeAccent.withValues(alpha: 0.8),
                color2: Colors.amberAccent.withValues(alpha: 0.4),
                coreRadius: size * 0.3,
                outerRadius: size * 0.5,
                blur: (30 * growth).clamp(1.0, 30.0),
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
      children: [
        Container().animate().custom(
          duration: 1500.ms,
          curve: Curves.easeOutBack,
          builder: (context, value, child) => CustomPaint(
            size: const Size(400, 400),
            painter: GlowPainter(
              color1: Colors.orangeAccent.withValues(alpha: 0.8),
              color2: Colors.amberAccent.withValues(alpha: 0.5),
              coreRadius: lerpDouble(80, 100, value)!,
              outerRadius: lerpDouble(120, 136, value)!,
              blur: lerpDouble(20, 22, value)!,
            ),
          ),
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
    ).animate().fade(duration: 2000.ms);
  }

  Widget _buildRewardDisplay() {
    final rewardId = widget.achievement.rewardDecorationId;
    final decoration = rewardId != null
        ? MascotDecoration.allDecorations
            .where((d) => d.id == rewardId)
            .firstOrNull
        : null;
    final bool isItem = decoration != null && decoration.path.isNotEmpty;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 240,
          height: 240,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isItem
                            ? Colors.orangeAccent.withValues(alpha: 0.4)
                            : Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
                if (isItem)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(decoration.path, width: 120, height: 120),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          decoration.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(color: Color(0xFFFFAB40), blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().scale(
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                    begin: const Offset(0.5, 0.5),
                  )
                else if (widget.achievement.rewardTitle != null)
                  // 只有称号奖励时，展示称号特有的 Badge
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.achievement.titleTier.badge,
                        size: 100,
                        color: widget.achievement.titleTier.color,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: widget.achievement.titleTier.cardGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: widget.achievement.titleTier.color.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.achievement.titleTier.badge, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              widget.achievement.rewardTitle!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'LXGWWenKai',
                                shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().scale(
                        duration: 800.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.5, 0.5),
                      )
                else
                  Icon(
                        Icons.military_tech,
                        size: 100,
                        color: Colors.amber.shade300,
                      )
                      .animate()
                      .scale(
                        duration: 800.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.5, 0.5),
                      )
                      .shimmer(duration: 2000.ms),
              ],
            ),
          ),
        ),
        Positioned(
          top: 250, // 放置在中心区域下方
          child: _buildSuccessText(),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 2500.ms);
  }

  Widget _buildSuccessText() {
    String rewardText = '';
    if (widget.achievement.rewardDecorationId != null) {
      final decoration = MascotDecoration.allDecorations
          .where((d) => d.id == widget.achievement.rewardDecorationId!)
          .firstOrNull;
      rewardText = '获得新饰品：${decoration?.name ?? "未知物品"}';
    } else if (widget.achievement.rewardTitle != null) {
      rewardText = '获得荣誉称号：${widget.achievement.rewardTitle}';
    } else {
      rewardText = '点数提高到 ${UserState().achievementPoints.value} 点';
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
              widget.achievement.title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 4.0,
                shadows: [
                  Shadow(color: Color(0xFFFFAB40), blurRadius: 30),
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            )
            .animate()
            .hide()
            .show(delay: 600.ms)
            .fadeIn(duration: 800.ms)
            .slideY(begin: 0.8, end: 0.0),
        const SizedBox(height: 12),
        Text(
              rewardText,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.amberAccent,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            )
            .animate()
            .hide()
            .show(delay: 900.ms)
            .fadeIn(duration: 1000.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
      ],
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
    isAtmospheric = index < atmosphericCount;
    if (isAtmospheric) {
      finalTargetRadius = 145 + rand.nextDouble() * 40;
      size = 2.2 + rand.nextDouble() * 2.8;
    } else {
      finalTargetRadius = rand.nextDouble() * 105;
      size = 1.2 + rand.nextDouble() * 2.4;
    }
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
    delay = math.pow(rand.nextDouble(), 0.5) * 0.72;
    swirlSpeed = (rand.nextDouble() - 0.5) * 5.0;
    rotationOffset = rand.nextDouble() * math.pi * 2;
    twinklePhase = rand.nextDouble() * math.pi * 2;
    twinkleSpeed = 2.5 + rand.nextDouble() * 3.5;
    atmospherePhaseOffset = rand.nextDouble() * math.pi * 2;
    breathPhase = rand.nextDouble() * math.pi * 2;
    breathSpeed = 3.0 + rand.nextDouble() * 2.5;
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
    final Offset center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();
    for (var p in particles) {
      double localProgress = (progress - p.delay) / 0.25;
      if (localProgress < 0) {
        continue;
      }
      final bool reachedCenter = localProgress >= 1.0;
      final double effectiveLP = reachedCenter ? 1.0 : localProgress;
      double alpha = 1.0;
      if (localProgress < 0.2) {
        alpha = localProgress / 0.2;
      }
      final currentRadius = lerpDouble(
        p.initialRadius,
        p.finalTargetRadius,
        math.pow(effectiveLP, 2.5).toDouble(),
      )!;
      double jX = 0.0;
      double jY = 0.0;
      if (reachedCenter) {
        jX = math.cos(p.rotationOffset + progress * 2) * (p.size * 0.5);
        jY = math.sin(p.rotationOffset + progress * 2) * (p.size * 0.5);
      }
      double oX = 0.0;
      double oY = 0.0;
      if (reachedCenter && p.isAtmospheric) {
        oX =
            math.cos(p.atmospherePhaseOffset + idleValue * math.pi * 4.0) * 8.0;
        oY =
            math.sin(p.atmospherePhaseOffset + idleValue * math.pi * 4.0) * 8.0;
      }
      double gFade = 1.0;
      if (progress > 0.85 && !p.isAtmospheric) {
        gFade = (1.0 - (progress - 0.85) / 0.15).clamp(0.0, 1.0);
      }
      double dIntensity = 0.15;
      if (progress > 0.82) {
        dIntensity = (0.15 + (progress - 0.82) / 0.13 * 0.85).clamp(0.15, 1.0);
      }
      double twinkle = 1.0;
      if (reachedCenter) {
        if (p.isAtmospheric) {
          twinkle =
              (1.0 - 0.4 * dIntensity) +
              math.sin(idleValue * math.pi * 12.0 + p.twinklePhase) *
                  0.4 *
                  dIntensity;
        } else {
          twinkle =
              0.65 +
              math.sin(progress * 60.0 * p.twinkleSpeed + p.twinklePhase) *
                  0.35;
        }
      }
      paint.color = p.color.withValues(
        alpha: (alpha * gFade * twinkle).clamp(0.0, 1.0),
      );
      double fSize = p.size;
      if (p.isAtmospheric && reachedCenter) {
        fSize =
            p.size *
            (1.0 +
                math.sin(idleValue * math.pi * 8.0 + p.breathPhase) *
                    0.35 *
                    dIntensity);
        canvas.drawCircle(
          Offset(
            center.dx + math.cos(p.initialAngle) * currentRadius + jX + oX,
            center.dy + math.sin(p.initialAngle) * currentRadius + jY + oY,
          ),
          fSize * 2.5,
          Paint()
            ..color = p.color.withValues(alpha: paint.color.a * 0.12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      final Offset pos = Offset(
        center.dx + math.cos(p.initialAngle) * currentRadius + jX + oX,
        center.dy + math.sin(p.initialAngle) * currentRadius + jY + oY,
      );
      if (p.type == ParticleType.circle) {
        canvas.drawCircle(pos, fSize, paint);
      } else if (p.type == ParticleType.star) {
        final s = fSize * 1.5;
        final path = Path()
          ..moveTo(pos.dx, pos.dy - s)
          ..quadraticBezierTo(pos.dx, pos.dy, pos.dx + s, pos.dy)
          ..quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + s)
          ..quadraticBezierTo(pos.dx, pos.dy, pos.dx - s, pos.dy)
          ..quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - s);
        canvas.drawPath(path, paint);
      } else if (p.type == ParticleType.diamond) {
        final s = fSize * 1.3;
        final path = Path()
          ..moveTo(pos.dx, pos.dy - s)
          ..lineTo(pos.dx + s, pos.dy)
          ..lineTo(pos.dx, pos.dy + s)
          ..lineTo(pos.dx - s, pos.dy)
          ..close();
        canvas.drawPath(path, paint);
      } else if (p.type == ParticleType.ring) {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 0.8;
        canvas.drawCircle(pos, fSize * 1.2, paint);
        paint.style = PaintingStyle.fill;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter old) =>
      old.progress != progress || old.idleValue != idleValue;
}

class GlowPainter extends CustomPainter {
  final Color color1, color2;
  final double coreRadius, outerRadius, blur;
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
      colors: [color1, color1.withValues(alpha: 0)],
      stops: const [0.5, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: coreRadius));
    canvas.drawCircle(center, coreRadius, paint);
    paint.shader = RadialGradient(
      colors: [color2.withValues(alpha: 0.6), color2.withValues(alpha: 0)],
      stops: const [0.3, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius, paint);
  }

  @override
  bool shouldRepaint(covariant GlowPainter old) =>
      old.coreRadius != coreRadius ||
      old.outerRadius != outerRadius ||
      old.blur != blur;
}
