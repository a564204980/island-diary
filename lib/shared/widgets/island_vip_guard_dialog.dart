import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/profile/presentation/pages/vip_benefits_page.dart';

/// 岛屿 VIP 拦截与引导弹窗
/// 采用“星光计划”的高级感磨砂玻璃视觉设计
class IslandVipGuardDialog extends StatelessWidget {
  final String title;
  final String description;
  final String benefitText;

  const IslandVipGuardDialog({
    super.key,
    required this.title,
    this.description = '开启“星光计划”，解锁更广阔的记录空间',
    this.benefitText = '单篇日记支持无限图片载入 · 自由图文混排',
  });

  @override
  Widget build(BuildContext context) {
    const starlightColor = Color(0xFFCE93D8);
    final isNight = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: starlightColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 核心图标
                    _buildInsignia(starlightColor),
                    const SizedBox(height: 32),
                    
                    // 标题
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'LXGWWenKai',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 16),
                    // 描述
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'LXGWWenKai',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                        height: 1.6,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    
                    const SizedBox(height: 32),
                    // 权益高亮框
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 16, color: starlightColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              benefitText,
                              style: const TextStyle(
                                fontFamily: 'LXGWWenKai',
                                fontSize: 13,
                                color: starlightColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 48),
                    // 行动按钮
                    _buildActionButton(context, starlightColor),
                    
                    const SizedBox(height: 12),
                    // 取消按钮
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '稍后再说',
                        style: TextStyle(
                          fontFamily: 'LXGWWenKai',
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsignia(Color color) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 2),
        ],
      ),
      child: CustomPaint(
        painter: _StarPainter(color: color),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeInOutSine);
  }

  Widget _buildActionButton(BuildContext context, Color themeColor) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VipBenefitsPage()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [themeColor, themeColor.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '申领星光计划契约',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai',
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5, end: 0);
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  _StarPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // 1. 渐变核心光晕
    canvas.drawCircle(center, size.width * 0.4, Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, color.withValues(alpha: 0.4), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2)));
      
    // 2. 极简十字星芒 (使用已定义的 starPaint)
    final starPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
      
    canvas.drawLine(Offset(center.dx, center.dy - 22), Offset(center.dx, center.dy + 22), starPaint);
    canvas.drawLine(Offset(center.dx - 22, center.dy), Offset(center.dx + 22, center.dy), starPaint);
    
    // 3. 中心凝聚点
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
    canvas.drawCircle(center, 1.5, Paint()..color = color);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
