import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: !isVip
            ? Border.all(
                color: isNight
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.6),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isVip
                ? const Color(0xFFAB47BC).withValues(alpha: 0.3)
                : (isNight
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFFB0BEC5).withValues(alpha: 0.2)),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // 极光渐变背景
            Positioned.fill(
              child: AnimatedGradient(isVip: isVip, isNight: isNight),
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
                              color: isVip
                                  ? Colors.white
                                  : (isNight ? Colors.white : const Color(0xFF3E2723)),
                              letterSpacing: 1,
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                          Text(
                            isVip ? '您的岛屿正沐浴在永恒星光中' : '让每一份心情都拥有流光溢彩的家',
                            style: TextStyle(
                              fontSize: 11,
                              color: isVip
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : (isNight ? Colors.white38 : Colors.black38),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        isVip ? Icons.workspace_premium : Icons.stars,
                        color: isVip
                            ? const Color(0xFFFFF176)
                            : (isNight ? Colors.white24 : Colors.black12),
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
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isVip
                            ? Colors.white.withValues(alpha: 0.2)
                            : (isNight ? Colors.white : const Color(0xFF3E2723)),
                        borderRadius: BorderRadius.circular(16),
                        border: isVip ? Border.all(color: Colors.white30) : null,
                      ),
                      child: Text(
                        isVip ? '查看专属权益' : '立即入驻',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isVip
                              ? Colors.white
                              : (isNight ? const Color(0xFF3E2723) : Colors.white),
                          fontFamily: 'LXGWWenKai',
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
              colors: widget.isVip
                  ? [
                      const Color(0xFFCE93D8),
                      const Color(0xFF7E57C2),
                      const Color(0xFF42A5F5),
                    ]
                  : (widget.isNight
                      ? [const Color(0xFF37474F), const Color(0xFF263238)]
                      : [
                          Colors.white.withValues(alpha: 0.9),
                          Colors.white.withValues(alpha: 0.8),
                        ]),
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
