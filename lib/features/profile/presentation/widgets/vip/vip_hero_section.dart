import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/profile/presentation/widgets/vip/vip_parallax_background.dart';

class VipHeroSection extends StatelessWidget {
  final bool isNight;
  final Color themeColor;

  const VipHeroSection({
    super.key,
    required this.isNight,
    required this.themeColor
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isNight ? Colors.white : const Color(0xFF3E2723);
    
    return Column(
      children: [
        // 具象化星芒中心 (Energy Field - 星钻核心)
        Stack(
          alignment: Alignment.center,
          children: [
            // 背景深度光晕
            Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [themeColor.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),

            // 星辰运行轨道 (Interstellar Orbits)
            ...List.generate(3, (index) => _buildCelestialOrbit(themeColor, index)),
            
            // 中层呼吸感扩散
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [themeColor.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 4.seconds, begin: const Offset(0.7, 0.7), end: const Offset(1.3, 1.3), curve: Curves.easeInOutExpo),

            // 核心勋章 - 星钻切面
            Container(
              width: 165,
              height: 165,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.4),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: StarlightInsigniaPainter(themeColor: themeColor),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 5.seconds, begin: const Offset(1, 1), end: const Offset(1.06, 1.06), curve: Curves.easeInOutSine),
          ],
        ),

        const SizedBox(height: 60),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isNight 
              ? [Colors.white, themeColor.withValues(alpha: 0.5), Colors.white, const Color(0xFFFFD4AF), Colors.white]
              : [const Color(0xFF3E2723), themeColor, const Color(0xFF3E2723), const Color(0xFFB8860B), const Color(0xFF3E2723)],
            stops: const [0, 0.25, 0.5, 0.75, 1],
          ).createShader(bounds),
          child: const Text(
            '星光计划 · 拾光伴侣',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 10,
              color: Colors.white,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
        
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border_rounded, size: 14, color: themeColor.withValues(alpha: 0.4)),
            const SizedBox(width: 14),
            Container(
              height: 0.8,
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, themeColor.withValues(alpha: 0.3), Colors.transparent]),
              ),
            ),
            const SizedBox(width: 14),
            Icon(Icons.star_border_rounded, size: 14, color: themeColor.withValues(alpha: 0.4)),
          ],
        ).animate().scaleX(begin: 0, end: 1, delay: 400.ms),
        const SizedBox(height: 24),
        
        Text(
          '✧  万象更新，在此间寻得永恒之光  ✧',
          style: TextStyle(
            fontSize: 15,
            color: textColor.withValues(alpha: 0.3),
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
            fontFamily: 'LXGWWenKai',
          ),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Widget _buildCelestialOrbit(Color themeColor, int index) {
    // 创建交错的旋转轨道
    final angles = [0.0, 60 * math.pi / 180, -60 * math.pi / 180];
    final durations = [30, 45, 60];
    
    return Transform.rotate(
      angle: angles[index],
      child: Container(
        width: 280,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.elliptical(280, 100)),
          border: Border.all(color: themeColor.withValues(alpha: 0.08), width: 0.8),
        ),
        child: Stack(
          children: [
            // 轨道亮点 (Pearl)
            OrbitingPearl(duration: durations[index], themeColor: themeColor),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat())
       .rotate(duration: durations[index].seconds, begin: 0, end: index % 2 == 0 ? 1 : -1),
    );
  }
}

class StarlightInsigniaPainter extends CustomPainter {
  final Color themeColor;
  StarlightInsigniaPainter({required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. 底层幻影光晕
    canvas.drawCircle(center, radius, Paint()
      ..shader = RadialGradient(
        colors: [themeColor.withValues(alpha: 0.6), themeColor.withValues(alpha: 0.1), Colors.transparent],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius)));

    // 2. 钻石切面绘制 (Faceted Diamond Effect)
    const points = 8;
    for (int i = 0; i < points; i++) {
        final angleTip = (i * 45 - 90) * math.pi / 180;
        final angleValleyNext = ((i * 45 + 22.5) - 90) * math.pi / 180;
        final angleValleyPrev = ((i * 45 - 22.5) - 90) * math.pi / 180;

        final pTip = center + Offset(radius * 0.8 * math.cos(angleTip), radius * 0.8 * math.sin(angleTip));
        final pValleyNext = center + Offset(radius * 0.3 * math.cos(angleValleyNext), radius * 0.3 * math.sin(angleValleyNext));
        final pValleyPrev = center + Offset(radius * 0.3 * math.cos(angleValleyPrev), radius * 0.3 * math.sin(angleValleyPrev));

        // 右半切面
        final pathRight = Path()..moveTo(center.dx, center.dy)..lineTo(pTip.dx, pTip.dy)..lineTo(pValleyNext.dx, pValleyNext.dy)..close();
        final paintRight = Paint()..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.9), themeColor.withValues(alpha: 0.3)],
        ).createShader(pathRight.getBounds());
        canvas.drawPath(pathRight, paintRight);

        // 左半切面
        final pathLeft = Path()..moveTo(center.dx, center.dy)..lineTo(pTip.dx, pTip.dy)..lineTo(pValleyPrev.dx, pValleyPrev.dy)..close();
        final paintLeft = Paint()..shader = LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [Colors.white.withValues(alpha: 0.7), themeColor.withValues(alpha: 0.1)],
        ).createShader(pathLeft.getBounds());
        canvas.drawPath(pathLeft, paintLeft);
    }

    // 3. 核心星芒射线 (Flares)
    final flaresPaint = Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 1.0;
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - 90) * math.pi / 180;
      final start = center + Offset(radius * 0.2 * math.cos(angle), radius * 0.2 * math.sin(angle));
      final end = center + Offset(radius * 1.5 * math.cos(angle), radius * 1.5 * math.sin(angle));
      canvas.drawLine(start, end, flaresPaint);
    }
    
    // 4. 晶体高光
    canvas.drawCircle(center, 4, Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
