import 'dart:ui';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';

/// 玻璃拟态月度日历卡片
class MonthCalendarCard extends StatelessWidget {
  final int year;
  final int month;
  final List<DiaryEntry> monthDiaries;
  final Duration? delay;

  const MonthCalendarCard({
    super.key,
    required this.year,
    required this.month,
    required this.monthDiaries,
    this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    // 计算当月天数和起始周几
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday; // 1:周一, ..., 7:周日

    // 统计数据
    final int recordDays =
        monthDiaries.map((e) => e.dateTime.day).toSet().length;
    final int totalWords = monthDiaries.fold(
      0,
      (sum, e) => sum + e.content.length,
    );

    final Color colorBase = isNight ? const Color(0xFF1A2A5E) : Colors.white;
    final Color vineGold = const Color(0xFFF8E8A0);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return RepaintBoundary( // 添加绘制边界，提升滚动性能并稳定模糊
      child: Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNight ? vineGold.withOpacity(0.5) : Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isNight ? 0.3 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(24),
            color: isNight ? colorBase.withOpacity(0.6) : Colors.white.withOpacity(0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(year, month, isNight, vineGold),
                const SizedBox(height: 20),
                _buildWeekHeader(),
                const SizedBox(height: 12),
                _buildCalendarGrid(daysInMonth, firstWeekday),
                const SizedBox(height: 20),
                _buildFooter(recordDays, monthDiaries.length, totalWords),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: delay ?? Duration.zero).scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.easeOutQuint,
        ).fadeIn(duration: 400.ms);
  }

  Widget _buildHeader(int year, int month, bool isNight, Color glowColor) {
    return Text(
      '$year年${month.toString().padLeft(2, '0')}月',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          if (isNight)
            Shadow(
              color: glowColor.withOpacity(0.4),
              blurRadius: 8,
            ),
          Shadow(
            color: Colors.black.withOpacity(isNight ? 0.3 : 0.1),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    const weeks = ['一', '二', '三', '四', '五', '六', '日'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weeks
          .map(
            (w) => Expanded(
              child: Center(
                child: Text(
                  w,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid(int daysInMonth, int firstWeekday) {
    // 前置空白格 (firstWeekday: 1-7, 周一为1)
    final int prefixEmpty = firstWeekday - 1;
    final totalCells = prefixEmpty + daysInMonth;
    final int rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Row(
          children: List.generate(7, (colIndex) {
            final int cellIndex = rowIndex * 7 + colIndex;
            final int day = cellIndex - prefixEmpty + 1;

            if (day <= 0 || day > daysInMonth) {
              return const Expanded(child: SizedBox());
            }

            // 查找当日记录
            final dayDiaries = monthDiaries
                .where((e) => e.dateTime.day == day)
                .toList();

            return Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: _CalendarDayCell(
                  year: year,
                  month: month,
                  day: day,
                  diaries: dayDiaries,
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildFooter(int days, int entries, int words) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$days天 | $entries篇 | $words字',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int year;
  final int month;
  final int day;
  final List<DiaryEntry> diaries;

  const _CalendarDayCell({
    required this.year,
    required this.month,
    required this.day,
    required this.diaries,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasRecord = diaries.isNotEmpty;
    // 检查是否为今天
    final now = DateTime.now();
    final bool isToday =
        now.year == year && now.month == month && now.day == day;

    if (!hasRecord) {
      return Center(
        child: Text(
          '$day',
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4)),
        ),
      );
    }

    // 优先级解析逻辑 (遍历所有日记)
    String? rewardPath;
    String? imagePath;
    int? moodIndex;

    for (var diary in diaries) {
      // 只要有一个日记有奖励，就用那个奖励（除非后面有更好的奖励？）
      // 这里可以按全天日记中最特殊的来挑选
      for (var blockMap in diary.blocks) {
        final block = DiaryBlock.fromMap(blockMap);
        if (block is RewardBlock && rewardPath == null) {
          rewardPath = block.imagePath;
        } else if (block is ImageBlock && imagePath == null) {
          imagePath = block.file.path;
        }
      }
      moodIndex ??= diary.moodIndex;
    }

    final bool isReward = rewardPath != null;
    final bool isImage = imagePath != null;
    final int count = diaries.length;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 叠纸底层效果 (大于1篇时显示)
          if (count > 1)
            Positioned(
              top: 6,
              left: 6,
              right: 2,
              bottom: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          if (count > 2)
            Positioned(
              top: 8,
              left: 8,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

          // 主体 Container
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                isReward ? 0.3 : (hasRecord ? 0.15 : 0),
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: isReward
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFF9C4).withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : (isToday
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null),
              border: Border.all(
                color: isToday
                    ? Colors.white.withOpacity(0.6)
                    : Colors.white.withOpacity(isReward ? 0.4 : 0.1),
                width: isToday ? 2.0 : (isReward ? 1.5 : 0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 封面图内容
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(isReward ? 6 : (isImage ? 0 : 8)),
                      child: _buildCover(rewardPath, imagePath, moodIndex),
                    ),
                  ),

                  // 底部高光（如果是奖励）
                  if (isReward)
                    Positioned(
                      bottom: -10,
                      child: Container(
                        width: 40,
                        height: 20,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 日期数字小角标
                  Positioned(
                    top: 5,
                    left: 6,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(isReward ? 0.9 : 0.6),
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 篇数角标 (如果是多篇)
                  if (count > 1)
                    Positioned(
                      bottom: 4,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(String? rewardPath, String? imagePath, int? moodIndex) {
    // 优先级调整：图片 > 奖励 > 心情
    if (imagePath != null) {
      if (kIsWeb ||
          imagePath.startsWith('http') ||
          imagePath.startsWith('blob:')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildCover(rewardPath, null, moodIndex);
          },
        );
      }
      return Image.file(
        io.File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildCover(rewardPath, null, moodIndex);
        },
      );
    }
    if (rewardPath != null) {
      return Image.asset(
        rewardPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildCover(null, null, moodIndex);
        },
      );
    }
    if (moodIndex != null && moodIndex < kMoods.length) {
      final mood = kMoods[moodIndex];
      if (mood.iconPath != null) {
        return Image.asset(
          mood.iconPath!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackMood(mood),
        );
      }
      return _buildFallbackMood(mood);
    }
    return const Icon(Icons.star, color: Colors.white24, size: 16);
  }

  Widget _buildFallbackMood(dynamic mood) {
    return Center(
      child: Text(
        mood.label.substring(0, 1),
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
