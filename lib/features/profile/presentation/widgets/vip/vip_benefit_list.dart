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
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFFFFD54F),
        isNight: isNight,
      ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),

      _buildHorizontalBenefitCard(
        title: '审美特权',
        description: '开启独家季节主题与霞鹜人文字体',
        icon: Icons.palette_rounded,
        iconColor: themeColor,
        isNight: isNight,
      ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
      
      _buildHorizontalBenefitCard(
        title: '无限灵感',
        description: '解锁笔记数量限制，支持无限高清图片',
        icon: Icons.all_inclusive_rounded,
        iconColor: const Color(0xFFF48FB1),
        isNight: isNight,
      ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
      
      _buildHorizontalBenefitCard(
        title: '仪式导出',
        description: '支持高精 PDF 打印与精美卡片分享',
        icon: Icons.ios_share_rounded,
        iconColor: const Color(0xFF4DB6AC),
        isNight: isNight,
      ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
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
    required IconData icon,
    required Color iconColor,
    required bool isNight,
  }) {
    final textColor = isNight ? Colors.white : const Color(0xFF3E2723);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.05) : iconColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.white,
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
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
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
                        color: textColor.withValues(alpha: 0.6),
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
    );
  }
}
