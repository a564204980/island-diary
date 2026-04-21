import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'diary_painters.dart';

/// 日记信纸上方的浮动心情标签
class MoodTag extends StatelessWidget {
  final String iconPath;
  final String description;

  const MoodTag({super.key, required this.iconPath, required this.description});

  @override
  Widget build(BuildContext context) {
    final isNight = UserState().isNight;
    return CustomPaint(
      painter: HandDrawnTagPainter(
        color: isNight 
            ? const Color(0xFF1F1F35).withValues(alpha: 0.85) // 带有月光蓝调的深色背景
            : const Color.fromRGBO(249, 238, 216, 0.75).withValues(alpha: 0.95),
        borderColor: isNight
            ? const Color(0xFFE0C097).withValues(alpha: 0.5)
            : const Color(0xFF8B5E3C).withValues(alpha: 0.4),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(iconPath, width: 24, height: 24),
            const SizedBox(width: 8),
            Text(
              description,
              style: TextStyle(
                color: isNight ? const Color(0xFFE0C097) : const Color(0xFF5D4037),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).moveY(begin: 10, end: 0);
  }
}
