import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VipBenefitList extends StatelessWidget {
  final bool isNight;
  final Color themeColor;
  final bool isWide;

  const VipBenefitList({
    super.key,
    required this.isNight,
    required this.themeColor,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _buildHorizontalBenefitCard(
        title: '专属装扮',
        description: '激活不同档位，即赠顶级稀有饰品及首发专属形象',
        orbColor: const Color(0xFFFFD54F),
        isNight: isNight,
      ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),

      _buildHorizontalBenefitCard(
        title: '审美特权',
        description: '开启独家季节主题与霞鹜人文字体',
        orbColor: themeColor,
        isNight: isNight,
      ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
      
      _buildHorizontalBenefitCard(
        title: '无限灵感',
        description: '解锁笔记数量限制，支持无限高清图片',
        orbColor: const Color(0xFFF48FB1),
        isNight: isNight,
      ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
      
      _buildHorizontalBenefitCard(
        title: '深度洞察',
        description: '365天情绪热力图与灵魂演化分析',
        orbColor: const Color(0xFF64B5F6),
        isNight: isNight,
      ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

      _buildHorizontalBenefitCard(
        title: '仪式导出',
        description: '支持高精 PDF 打印与精美卡片分享',
        orbColor: const Color(0xFF4DB6AC),
        isNight: isNight,
      ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),

      _buildHorizontalBenefitCard(
        title: '同步无界',
        description: '多端实时云同步，数据端到端加密',
        orbColor: const Color(0xFF9575CD),
        isNight: isNight,
      ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),
    ];

    if (isWide) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 16,
          mainAxisExtent: 96,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => items[index],
          childCount: items.length,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate(items),
    );
  }

  Widget _buildHorizontalBenefitCard({
    required String title,
    required String description,
    required Color orbColor,
    required bool isNight,
  }) {
    final textColor = isNight ? Colors.white : const Color(0xFF3E2723);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.05) : orbColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isNight ? Colors.white.withValues(alpha: 0.12) : Colors.white,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isNight ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                SoulOrb(color: orbColor, size: 36),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'LXGWWenKai',
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.5),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SoulOrb extends StatelessWidget {
  final Color color;
  final double size;
  const SoulOrb({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: CustomPaint(painter: SoulOrbPainter(color: color)),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .scale(duration: 2.seconds, begin: const Offset(0.85, 0.85), end: const Offset(1.15, 1.15), curve: Curves.easeInOutSine);
  }
}

class SoulOrbPainter extends CustomPainter {
  final Color color;
  SoulOrbPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, color, color.withValues(alpha: 0)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
