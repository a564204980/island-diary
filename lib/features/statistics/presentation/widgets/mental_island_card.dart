import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/statistics/domain/utils/soul_season_logic.dart';
import 'package:island_diary/features/statistics/presentation/widgets/seasonal_atmosphere_painter.dart';

class MentalIslandCard extends StatelessWidget {
  final SoulSeasonResult season;
  final bool isNight;
  final int totalEntries;
  final String rangeText;

  const MentalIslandCard({
    super.key,
    required this.season,
    required this.isNight,
    required this.totalEntries,
    this.rangeText = '当前',
  });

  @override
  Widget build(BuildContext context) {
    // 繁荣度缩放系数
    final double scaling = (0.9 + (min(totalEntries, 50) / 50) * 0.3).clamp(0.9, 1.2);
    
    return Container(
      width: double.infinity,
      height: 240, // 增加高度，提供更多视觉呼吸空间
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), // 还原为 24，保持与其他模块一致
        boxShadow: [
          BoxShadow(
            color: isNight 
                ? Colors.black.withValues(alpha: 0.4) 
                : season.accentColor.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // --- Layer 1: 动态网格背景渲染 ---
            Positioned.fill(
              child: _MeshGradientBackground(
                baseColor: season.accentColor,
                isNight: isNight,
              ),
            ),

            // --- Layer 2: 氛围粒子系统 (集成的 SeasonalAtmosphere) ---
            Positioned.fill(
              child: Opacity(
                opacity: 0.6,
                child: SeasonalAtmosphere(
                  particleType: season.particleType,
                  isNight: isNight,
                ),
              ),
            ),

            // --- Layer 3: 玻璃态磨砂层 ---
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isNight 
                        ? Colors.black.withValues(alpha: 0.15) 
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: isNight ? 0.05 : 0.4),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isNight ? 0.1 : 0.6),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // --- Layer 4: 核心内容渲染 ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 岛屿视觉核心（流光设计）
                      _buildGlowingIcon(season.icon, scaling),
                      const SizedBox(width: 24),
                      // 文案排版
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$rangeText灵魂处于',
                              style: TextStyle(
                                fontSize: 13,
                                letterSpacing: 1.5,
                                color: isNight ? Colors.white54 : const Color(0xFF5A3E28).withValues(alpha: 0.7),
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                            const SizedBox(height: 4),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: isNight 
                                  ? [Colors.white, season.accentColor.withValues(alpha: 0.5)]
                                  : [const Color(0xFF5A3E28), season.accentColor],
                              ).createShader(bounds),
                              child: Text(
                                season.seasonName,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'LXGWWenKai',
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isNight 
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : season.accentColor.withValues(alpha: 0.25), // 白天模式增加背景深度
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isNight 
                                    ? Colors.white.withValues(alpha: 0.1) 
                                    : season.accentColor.withValues(alpha: 0.3)
                                ),
                              ),
                              child: Text(
                                '已记录 $totalEntries 次时光印记',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isNight 
                                    ? Colors.white70 
                                    : const Color(0xFF5A3E28).withValues(alpha: 0.8), // 使用深棕色增加对比度
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // AI 洞察/寄语区 (浮动磨砂卡片)
                  ValueListenableBuilder<String?>(
                    valueListenable: UserState().lastSoulInsight,
                    builder: (context, aiInsight, _) {
                      final displayMessage = (aiInsight != null && aiInsight.isNotEmpty) 
                          ? aiInsight 
                          : season.healingMessage;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isNight 
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(24), // 增加内层圆角
                          border: Border.all(color: Colors.white.withValues(alpha: isNight ? 0.05 : 0.6)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              (aiInsight != null && aiInsight.isNotEmpty) 
                                  ? CupertinoIcons.sparkles 
                                  : CupertinoIcons.quote_bubble_fill, 
                              size: 16, 
                              color: season.accentColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                displayMessage,
                                style: TextStyle(
                                  color: isNight ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'LXGWWenKai',
                                  height: 1.6,
                                ),
                              ).animate(key: ValueKey(displayMessage)).fadeIn(duration: 800.ms).moveY(begin: 5, end: 0),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowingIcon(String icon, double scaling) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 背景发光层
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: season.accentColor.withValues(alpha: 0.4),
                blurRadius: 25,
                spreadRadius: 5,
              )
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(duration: 2.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
        
        // 核心容器
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                season.accentColor.withValues(alpha: 0.8),
                season.accentColor.withValues(alpha: 0.4),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
          ),
          child: Transform.scale(
            scale: scaling,
            child: Text(icon, style: const TextStyle(fontSize: 32)),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .moveY(begin: -2, end: 2, duration: 1.5.seconds, curve: Curves.easeInOut),
      ],
    );
  }
}

/// 动态网格背景渲染器
class _MeshGradientBackground extends StatefulWidget {
  final Color baseColor;
  final bool isNight;

  const _MeshGradientBackground({required this.baseColor, required this.isNight});

  @override
  State<_MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<_MeshGradientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_MeshBlob> _blobs = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    
    // 初始化三个不同速度和方向的色块
    _blobs.add(_MeshBlob(color: widget.baseColor.withValues(alpha: 0.3), size: 180, speed: 1.0));
    _blobs.add(_MeshBlob(color: Colors.cyan.withValues(alpha: 0.2), size: 220, speed: 0.8));
    _blobs.add(_MeshBlob(color: widget.isNight ? Colors.indigo.withValues(alpha: 0.4) : Colors.amber.withValues(alpha: 0.1), size: 200, speed: 1.2));
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
      builder: (context, _) {
        return Stack(
          children: _blobs.map((blob) {
            blob.update(_controller.value);
            return Positioned(
              left: blob.x,
              top: blob.y,
              child: Container(
                width: blob.size,
                height: blob.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blob.color,
                  boxShadow: [
                    BoxShadow(
                      color: blob.color,
                      blurRadius: 80,
                      spreadRadius: 20,
                    )
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MeshBlob {
  final Color color;
  final double size;
  final double speed;
  double x = 0;
  double y = 0;
  double _angle;

  _MeshBlob({required this.color, required this.size, required this.speed})
      : _angle = Random().nextDouble() * pi * 2;

  void update(double t) {
    final double time = DateTime.now().millisecondsSinceEpoch / 2000.0 * speed;
    x = 100 + cos(time + _angle) * 120;
    y = 60 + sin(time * 0.8 + _angle) * 80;
  }
}

