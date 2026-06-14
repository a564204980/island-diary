import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/pages/vip_benefits_page.dart';

class PremiumBentoCard extends StatelessWidget {
  final bool isVip;
  final bool isNight;

  const PremiumBentoCard({
    super.key,
    required this.isVip,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final String themeId = UserState().selectedIslandThemeId.value;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: themeId == 'lego'
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.6), // 100% 还原图1中极为精致柔和的卡片外圈白描边
                width: 1.5,
              )
            : (!isVip
                ? Border.all(
                    color: isNight
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.6),
                  )
                : null),
        boxShadow: [
          BoxShadow(
            color: themeId == 'lego'
                ? const Color(0xFF9A74EC).withValues(alpha: 0.18) // 稍微加一点色彩浓度，保证浮动微光感
                : (isVip
                    ? const Color(0xFFAB47BC).withValues(alpha: 0.3)
                    : (isNight
                        ? Colors.black.withValues(alpha: 0.3)
                        : const Color(0xFFB0BEC5).withValues(alpha: 0.2))),
            blurRadius: themeId == 'lego' ? 16 : 20, // 稍微蓬松一点，营造浮动空气感
            spreadRadius: themeId == 'lego' ? 1 : 2, // 稍微带 1 像素扩展，表现自然微光
            offset: themeId == 'lego' ? const Offset(0, 6) : const Offset(0, 10), // 微调向下偏移，体现悬浮高度
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 极光渐变背景 / 乐高专属卡面背景
            Positioned.fill(
              child: themeId == 'lego'
                  ? Image.asset(
                      'assets/images/theme/legao/my/my_vip_bg.png',
                      fit: BoxFit.cover,
                    )
                  : AnimatedGradient(isVip: isVip, isNight: isNight),
            ),

            // 内容
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isVip ? '星光计划 · 已激活' : '星光计划 · 永久居民',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1,
                              fontFamily: _getFontFamily(),
                            ),
                          ),
                          Text(
                            isVip ? '您的岛屿正沐浴在永恒星光中' : '让每一份心情都拥有流光溢彩的家',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontFamily: _getFontFamily(),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        isVip ? Icons.workspace_premium : Icons.stars,
                        color: isVip ? const Color(0xFFFFF176) : Colors.white24,
                        size: 32,
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VipBenefitsPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: themeId == 'lego'
                            ? const Color(0xFFEADBFC) // 柔和且不透明的马卡龙淡粉紫色背景，与底色完美契合
                            : (isVip
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.white),
                        borderRadius: BorderRadius.circular(99), // 完美胶囊圆角
                        border: themeId == 'lego'
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.45), // 精致的白色描边
                                width: 1,
                              )
                            : null,
                        boxShadow: themeId == 'lego'
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        themeId == 'lego' ? '查看专属权益' : (isVip ? '查看专属权益' : '立即入驻'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: themeId == 'lego'
                              ? const Color(0xFF673AB7) // 深靛紫色，与实色淡粉紫底高对比度且融洽
                              : (isVip
                                  ? Colors.white
                                  : const Color(0xFF673AB7)),
                          fontFamily: _getFontFamily(),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic, delay: 300.ms).fadeIn(delay: 300.ms);
  }

  String _getFontFamily() {
    return UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
  }
}

/// 动感渐变背景
class AnimatedGradient extends StatefulWidget {
  final bool isVip;
  final bool isNight;
  const AnimatedGradient({
    super.key,
    required this.isVip,
    required this.isNight,
  });

  @override
  State<AnimatedGradient> createState() => _AnimatedGradientState();
}

class _AnimatedGradientState extends State<AnimatedGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFCE93D8),
                const Color(0xFF7E57C2),
                const Color(0xFF42A5F5),
              ],
              stops: widget.isVip
                  ? [
                      0.0,
                      0.5 + 0.2 * math.sin(_controller.value * 2 * math.pi),
                      1.0,
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }
}
