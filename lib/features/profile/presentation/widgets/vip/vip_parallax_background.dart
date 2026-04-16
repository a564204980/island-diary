import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/statistics/domain/utils/soul_season_logic.dart';
import 'package:island_diary/features/statistics/presentation/widgets/seasonal_atmosphere_painter.dart';

class VipParallaxBackground extends StatelessWidget {
  final bool isNight;
  final SoulSeasonResult season;
  final double scrollOffset;

  const VipParallaxBackground({
    super.key,
    required this.isNight,
    required this.season,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 深遂空间背景
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isNight 
                ? [const Color(0xFF0F172A), const Color(0xFF020617)] 
                : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
            ),
          ),
        ),

        // 2. 远景：季节氛围粒子 (静态/慢速)
        Positioned.fill(
          child: Opacity(
            opacity: isNight ? 0.3 : 0.6,
            child: SeasonalAtmosphere(
              particleType: season.particleType,
              isNight: isNight,
            ),
          ),
        ),

        // 3. 中景：视差星辰
        ...List.generate(40, (index) {
          final random = math.Random(index);
          final speed = 0.05 + random.nextDouble() * 0.15;
          final top = random.nextDouble() * 1200 - (scrollOffset * speed);
          final left = random.nextDouble() * MediaQuery.of(context).size.width;
          final size = 1.0 + random.nextDouble() * 2.5;

          return Positioned(
            top: top,
            left: left,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isNight ? Colors.white : const Color(0xFF7E57C2)).withValues(alpha: 0.2 + random.nextDouble() * 0.5),
                boxShadow: [
                  BoxShadow(
                    color: (isNight ? Colors.white : const Color(0xFF7E57C2)).withValues(alpha: 0.2),
                    blurRadius: size * 2,
                  ),
                ],
              ),
            ),
          );
        }),

        // 4. 定向极光掠影 (动态)
        Positioned(
          top: 100 - (scrollOffset * 0.2),
          left: -150,
          child: _AuroraBeam(isNight: isNight),
        ),
      ],
    );
  }
}

class _AuroraBeam extends StatelessWidget {
  final bool isNight;
  const _AuroraBeam({required this.isNight});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.3,
      child: Container(
        width: 600,
        height: 300,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              (isNight ? const Color(0xFFCE93D8) : const Color(0xFF7E57C2)).withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .moveX(duration: 10.seconds, begin: -50, end: 150, curve: Curves.easeInOutExpo);
  }
}

class OrbitingPearl extends StatelessWidget {
  final int duration;
  final Color themeColor;

  const OrbitingPearl({
    super.key,
    required this.duration,
    required this.themeColor
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: themeColor.withValues(alpha: 0.8), blurRadius: 10, spreadRadius: 2),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat())
       .custom(
         duration: duration.seconds,
         builder: (context, val, child) {
           final angle = val * 2 * math.pi;
           return Transform.translate(
             offset: Offset(
               140 * math.cos(angle), // 轨道长轴
               50 * math.sin(angle),  // 轨道短轴
             ),
             child: child,
           );
         },
       ),
    );
  }
}
