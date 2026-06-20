import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/profile/presentation/pages/vip_benefits_page.dart';

/// 岛屿 VIP 拦截与引导弹窗
/// 采用“星光计划”的高级感磨砂玻璃与星空霓虹视觉设计
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
    const primaryStarColor = Color(0xFFC084FC); // 梦幻紫
    const secondaryStarColor = Color(0xFF818CF8); // 星空蓝

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 36),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F1123).withValues(alpha: 0.88),
                    const Color(0xFF1A162B).withValues(alpha: 0.88),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 核心华丽星芒
                    _buildInsignia(primaryStarColor),
                    const SizedBox(height: 28),
                    
                    // 标题
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'LXGWWenKai',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                    
                    const SizedBox(height: 12),
                    // 描述
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'LXGWWenKai',
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.55),
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    
                    const SizedBox(height: 26),
                    // 权益高亮框
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryStarColor.withValues(alpha: 0.08),
                            secondaryStarColor.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryStarColor.withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 16, color: primaryStarColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              benefitText,
                              style: const TextStyle(
                                fontFamily: 'LXGWWenKai',
                                fontSize: 12.5,
                                color: Color(0xFFE9D5FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(delay: 350.ms, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 36),
                    // 行动按钮
                    _buildActionButton(context, primaryStarColor, secondaryStarColor),
                    
                    const SizedBox(height: 10),
                    // 取消按钮
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        '稍后再说',
                        style: TextStyle(
                          fontFamily: 'LXGWWenKai',
                          color: Colors.white.withValues(alpha: 0.35),
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
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: 1),
        ],
      ),
      child: CustomPaint(
        painter: _StarPainter(color: color),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .scale(duration: 1800.ms, begin: const Offset(1, 1), end: const Offset(1.08, 1.08), curve: Curves.easeInOutSine);
  }

  Widget _buildActionButton(BuildContext context, Color color1, Color color2) {
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
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: color2.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '申领星光计划契约',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai',
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.25, end: 0, curve: Curves.easeOutBack);
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  _StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width * 0.36;

    // 1. 梦幻多层发光晕染
    for (double r = 0.9; r > 0.1; r -= 0.25) {
      canvas.drawCircle(
        center,
        size.width * 0.45 * r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.8),
              color.withValues(alpha: 0.4 * r),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.45 * r)),
      );
    }

    // 2. 绘制精美四角星 (带贝塞尔收腰的梦幻星)
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path drawSparkle(Offset c, double r) {
      final path = Path();
      path.moveTo(c.dx, c.dy - r);
      path.quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy);
      path.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r);
      path.quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy);
      path.quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r);
      path.close();
      return path;
    }

    // 绘制主四角星
    canvas.drawPath(drawSparkle(center, radius), starPaint);

    // 绘制交错旋转45度的小星，形成闪烁折射效果
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(3.1415926 / 4); // 45度
    canvas.drawPath(drawSparkle(Offset.zero, radius * 0.45), Paint()..color = Colors.white.withValues(alpha: 0.85));
    canvas.restore();

    // 3. 极细散射十字光轨
    final rayPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.45),
          Colors.white,
          Colors.white.withValues(alpha: 0.45),
          Colors.transparent
        ],
      ).createShader(Rect.fromLTRB(center.dx - radius * 1.6, center.dy - 1, center.dx + radius * 1.6, center.dy + 1))
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - radius * 1.6, center.dy), Offset(center.dx + radius * 1.6, center.dy), rayPaint);
    
    final rayPaintV = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.45),
          Colors.white,
          Colors.white.withValues(alpha: 0.45),
          Colors.transparent
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(center.dx - 1, center.dy - radius * 1.6, center.dx + 1, center.dy + radius * 1.6))
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, center.dy - radius * 1.6), Offset(center.dx, center.dy + radius * 1.6), rayPaintV);

    // 4. 中心凝聚强光点
    canvas.drawCircle(center, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
