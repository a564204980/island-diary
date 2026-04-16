import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';

class PricingTier {
  final String title;
  final String price;
  final double numericPrice;
  final String period;
  final String note;
  final bool isPop;

  const PricingTier({
    required this.title,
    required this.price,
    required this.numericPrice,
    required this.period,
    required this.note,
    this.isPop = false,
  });
}

class VipPricingSection extends StatelessWidget {
  final bool isNight;
  final Color themeColor;
  final int selectedIndex;
  final ValueChanged<int> onTierSelected;
  final List<PricingTier> tiers;

  const VipPricingSection({
    super.key,
    required this.isNight,
    required this.themeColor,
    required this.selectedIndex,
    required this.onTierSelected,
    required this.tiers,
  });

  double _getEffectivePrice(int targetIndex, int currentLevel) {
    final targetPrice = tiers[targetIndex].numericPrice;
    
    if (currentLevel == 0) return targetPrice;
    if ((targetIndex + 1) <= currentLevel) return 0.0;
    
    double paidAmount = 0.0;
    if (currentLevel == 1) {
      paidAmount = 3.0;
    } else if (currentLevel == 2) {
      paidAmount = 25.0;
    }
    
    return math.max(0.0, targetPrice - paidAmount);
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = UserState().vipLevel.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 20),
          child: Text(
            '选择你的拾光方案',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: (isNight ? Colors.white : const Color(0xFF3E2723)).withValues(alpha: 0.8),
              fontFamily: 'LXGWWenKai',
              letterSpacing: 2,
            ),
          ),
        ),
        ...List.generate(tiers.length, (index) {
          final tier = tiers[index];
          final isSelected = selectedIndex == index;
          final effectivePrice = _getEffectivePrice(index, currentLevel);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => onTierSelected(index),
              child: AnimatedContainer(
                duration: 400.ms,
                curve: Curves.easeOutQuint,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isNight ? themeColor.withValues(alpha: 0.15) : themeColor.withValues(alpha: 0.1))
                      : (isNight ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? themeColor : (isNight ? Colors.white12 : Colors.black12),
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))
                  ] : [],
                ),
                child: Row(
                  children: [
                    // 选中指示器
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? themeColor : (isNight ? Colors.white24 : Colors.black.withValues(alpha: 0.1)),
                          width: 2,
                        ),
                      ),
                      child: AnimatedScale(
                        duration: 300.ms,
                        scale: isSelected ? 1.0 : 0.0,
                        curve: Curves.easeOutBack,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: themeColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tier.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isNight ? Colors.white : const Color(0xFF3E2723),
                                  fontFamily: 'LXGWWenKai',
                                ),
                              ),
                              if (tier.isPop) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('推荐', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tier.note,
                            style: TextStyle(
                              fontSize: 12,
                              color: (isNight ? Colors.white : const Color(0xFF3E2723)).withValues(alpha: 0.4),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (effectivePrice < tier.numericPrice && effectivePrice > 0)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '补差价升级',
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                          ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '¥',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isNight ? Colors.white : const Color(0xFF3E2723),
                                ),
                              ),
                              TextSpan(
                                text: effectivePrice <= 0 ? (currentLevel >= (index + 1) ? '已激活' : '0.0') : effectivePrice.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: effectivePrice <= 0 && currentLevel >= (index + 1) ? 18 : 24,
                                  fontWeight: FontWeight.w900,
                                  color: isNight ? Colors.white : const Color(0xFF3E2723),
                                ),
                              ),
                              TextSpan(
                                text: tier.period,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: (isNight ? Colors.white : const Color(0xFF3E2723)).withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
