import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';

/// 玻璃拟态月度日历卡片
class MonthCalendarCard extends StatelessWidget {
  final int year;
  final int month;
  final List<DiaryEntry> monthDiaries;

  const MonthCalendarCard({
    super.key,
    required this.year,
    required this.month,
    required this.monthDiaries,
  });

  @override
  Widget build(BuildContext context) {
    // 计算当月天数和起始周几
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday; // 1:周一, ..., 7:周日

    // 统计数据
    final int recordDays = monthDiaries
        .map((e) => e.dateTime.day)
        .toSet()
        .length;
    final int totalWords = monthDiaries.fold(
      0,
      (sum, e) => sum + e.content.length,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 0.8,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                _buildHeader(),
                const SizedBox(height: 20),
                // 星期表头
                _buildWeekHeader(),
                const SizedBox(height: 12),
                // 日历网格
                _buildCalendarGrid(daysInMonth, firstWeekday),
                const SizedBox(height: 20),
                // 底部统计
                _buildFooter(recordDays, monthDiaries.length, totalWords),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      '$year年${month.toString().padLeft(2, '0')}月',
      style: const TextStyle(
        fontFamily: 'FZKai',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
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
                    fontFamily: 'FZKai',
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
                child: _CalendarDayCell(day: day, diaries: dayDiaries),
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
              fontFamily: 'FZKai',
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int day;
  final List<DiaryEntry> diaries;

  const _CalendarDayCell({required this.day, required this.diaries});

  @override
  Widget build(BuildContext context) {
    final bool hasRecord = diaries.isNotEmpty;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: hasRecord ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasRecord)
              // 这里暂时显示记录心情的占位，后续可换成精美插画
              _buildMoodIcon(diaries.first.moodIndex)
            else
              Text(
                '$day',
                style: TextStyle(
                  fontFamily: 'FZKai',
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),

            // 日期数字小角标（如果有记录，缩小放在角落）
            if (hasRecord)
              Positioned(
                top: 4,
                left: 4,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodIcon(int moodIndex) {
    // 方案：根据心情索引显示不同 Emoji 或图标
    // 实际项目中由于有 CustomPainter 或 Image 资源，这里可以根据 moodIndex 映射
    const moods = ['😊', '😔', '😡', '😴', '🎨', '🌟', '🍃', '🌊'];
    final String mood = moodIndex < moods.length ? moods[moodIndex] : '✨';

    return Text(mood, style: const TextStyle(fontSize: 18));
  }
}
