import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/vip/vip_pricing_section.dart';

class VipPurchaseButton extends StatelessWidget {
  final bool isNight;
  final Color themeColor;
  final int selectedIndex;
  final List<PricingTier> tiers;

  const VipPurchaseButton({
    super.key,
    required this.isNight,
    required this.themeColor,
    required this.selectedIndex,
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
    final userState = UserState();

    return ListenableBuilder(
      listenable: userState.vipLevel,
      builder: (context, _) {
        final bool isVip = userState.isVip.value;
        final textColor = isNight ? Colors.white : const Color(0xFF3E2723);
        final selectedTier = tiers[selectedIndex];
        final currentLevel = userState.vipLevel.value;

        return Column(
          children: [
            Text(
              isVip && currentLevel == 3 
                ? '—— 星河拾光之契已经激活 ——' 
                : (isVip 
                    ? '—— 有效期至：${userState.vipExpireTime.value?.toIso8601String().split('T')[0] ?? ''} ——' 
                    : '开启这扇门，通往更广阔的心灵原野'),
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.3),
                fontFamily: 'LXGWWenKai',
                letterSpacing: 2,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .shimmer(duration: 3.seconds),
            const SizedBox(height: 32),
            if (currentLevel < (selectedIndex + 1))
              GestureDetector(
                onTap: () async {
                  await userState.setIsVipLevel(selectedIndex + 1);
                  await userState.checkAchievements();
                },
                child: Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [themeColor, themeColor.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 4,
                        left: 40,
                        right: 40,
                        height: 1.5,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0)],
                            ),
                          ),
                        ),
                      ),
                      
                      Text(
                        '以 ¥${_getEffectivePrice(selectedIndex, currentLevel).toStringAsFixed(1)} ${selectedTier.period == '终身' ? '永久' : '激活'}${currentLevel > 0 ? '升级' : ''}${selectedTier.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LXGWWenKai',
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.03, 1.03), curve: Curves.easeInOutSine),
            const SizedBox(height: 16),
            if (!isVip)
              Text(
                '一次支持，全岛建设加速中',
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.2),
                  fontFamily: 'LXGWWenKai',
                  letterSpacing: 1,
                ),
              ),
          ],
        );
      },
    );
  }
}
