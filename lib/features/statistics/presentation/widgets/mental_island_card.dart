import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/statistics/domain/utils/soul_season_logic.dart';

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
    // 根据记录数量决定岛屿的“繁荣度”
    final double scaling = (0.8 + (min(totalEntries, 50) / 50) * 0.4).clamp(0.8, 1.2);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            season.accentColor.withOpacity(isNight ? 0.2 : 0.3),
            season.accentColor.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: season.accentColor.withOpacity(isNight ? 0.4 : 0.5), 
          width: 1.2
        ),
        boxShadow: [
          BoxShadow(
            color: isNight 
                ? Colors.black.withOpacity(0.3) 
                : Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 装饰：背景光晕
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: season.accentColor.withOpacity(isNight ? 0.15 : 0.2),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 3.seconds, begin: const Offset(1,1), end: const Offset(1.5,1.5)),
            ),
            
            // 岛屿主体与文案
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // 岛屿图标动画
                      Transform.scale(
                        scale: scaling,
                        child: _buildIslandVisual(season.icon),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut),
                      const SizedBox(width: 20),
                      // 右侧标题与统计
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$rangeText灵魂处于：${season.seasonName}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isNight ? Colors.white : const Color(0xFF5A3E28).withOpacity(0.9),
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '已在岛屿留下 $totalEntries 处时光印记',
                              style: TextStyle(
                                fontSize: 11,
                                color: isNight ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 治愈寄语融入卡片底部
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: season.accentColor.withOpacity(isNight ? 0.05 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: season.accentColor.withOpacity(isNight ? 0.1 : 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.sparkles, size: 14, color: season.accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            season.healingMessage,
                            style: TextStyle(
                              color: isNight ? Colors.white70 : Colors.black87,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'LXGWWenKai',
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 季节性图标修饰 (角落)
            Positioned(
              right: 12,
              bottom: 12,
              child: Opacity(
                opacity: 0.12,
                child: Icon(
                  _getSeasonIcon(season.particleType),
                  size: 32,
                  color: season.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIslandVisual(String icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: season.accentColor.withOpacity(0.1),
        boxShadow: [
          BoxShadow(
            color: season.accentColor.withOpacity(0.2), 
            blurRadius: 20, 
            spreadRadius: 2,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: season.accentColor.withOpacity(0.2), width: 1.5),
      ),
      child: Text(
        icon,
        style: const TextStyle(fontSize: 32),
      ),
    );
  }

  IconData _getSeasonIcon(String type) {
    switch (type) {
      case 'flower': return Icons.local_florist;
      case 'firefly': return Icons.wb_sunny;
      case 'leaf': return Icons.eco;
      case 'frost': return Icons.ac_unit;
      case 'rain': return Icons.umbrella;
      default: return Icons.wb_cloudy;
    }
  }
}
