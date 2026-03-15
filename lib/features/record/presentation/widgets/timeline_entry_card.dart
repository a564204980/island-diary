import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';

/// 时间轴上的单条记录卡片
class TimelineEntryCard extends StatelessWidget {
  final DiaryEntry diary;

  const TimelineEntryCard({super.key, required this.diary});

  @override
  Widget build(BuildContext context) {
    // 统一通过 UserState() 实时获取，避免多层嵌套监听
    final bool isNight = UserState().isNight;
    final mood = kMoods[diary.moodIndex.clamp(0, kMoods.length - 1)];
    final String dateStr = DateFormat('MM月dd日').format(diary.dateTime);
    final String timeStr = DateFormat('HH:mm').format(diary.dateTime);

    final Color colorBase = isNight ? const Color(0xFF736675) : Colors.white;
    final Color glowColor = const Color(0xFFFFF176);
    final Color borderColor =
        isNight ? glowColor.withOpacity(0.4) : glowColor.withOpacity(0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorBase.withOpacity(isNight ? 0.45 : 0.25),
            colorBase.withOpacity(isNight ? 0.25 : 0.1),
          ],
        ),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Image.asset(mood.iconPath!, width: 32, height: 32),
                    const SizedBox(height: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isNight
                            ? Colors.white70
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: (mood.glowColor ?? Colors.white)
                                  .withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        diary.content.replaceAll('\n', ' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isNight
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.7),
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
