import 'package:flutter/material.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';

class AchievementHeaderCard extends StatelessWidget {
  final int unlockedCount;
  final int totalPoints;
  final bool isNight;

  const AchievementHeaderCard({
    super.key,
    required this.unlockedCount,
    required this.totalPoints,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isNight ? Colors.white : const Color(0xFF1A1A1A);
    final total = MascotAchievement.allAchievements.length;
    final percent = total > 0 ? (unlockedCount / total * 100).toStringAsFixed(0) : '0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('已点亮', unlockedCount.toString(), '成就', textColor),
          _buildDivider(textColor),
          _buildStatItem('累计', totalPoints.toString(), '荣誉', textColor),
          _buildDivider(textColor),
          _buildStatItem('总完成度', '$percent%', '进度', textColor),
        ],
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Container(
      width: 1,
      height: 24,
      color: color.withValues(alpha: 0.1),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.4),
            fontFamily: 'LXGWWenKai',
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'Douyin',
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.6),
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
