import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 引入 flutter_animate
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

/// 日历格网面板 V6：动效同步版
class DiaryCalendarPanel extends StatefulWidget {
  final bool isNight;
  final Function(DateTime) onDateSelected;

  const DiaryCalendarPanel({
    super.key,
    required this.isNight,
    required this.onDateSelected,
  });

  @override
  State<DiaryCalendarPanel> createState() => _DiaryCalendarPanelState();
}

class _DiaryCalendarPanelState extends State<DiaryCalendarPanel> {
  final ScrollController _scrollController = ScrollController();
  final DateTime _now = DateTime.now();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _getMonthForIndex(int index) {
    return DateTime(_now.year, _now.month - index, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildStaticWeekRow(),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 80), 
              itemBuilder: (context, index) {
                return _MonthSection(
                  index: index, // 传递 index 用于 Stagger 动画
                  month: _getMonthForIndex(index),
                  isNight: widget.isNight,
                  onDateSelected: widget.onDateSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticWeekRow() {
    final List<String> weekDays = ["一", "二", "三", "四", "五", "六", "日"];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((d) => SizedBox(
          width: 40,
          child: Center(
            child: Text(
              d,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: widget.isNight ? Colors.white30 : Colors.black.withOpacity(0.12),
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  final int index; // 新增 index
  final DateTime month;
  final bool isNight;
  final Function(DateTime) onDateSelected;

  const _MonthSection({
    required this.index,
    required this.month,
    required this.isNight,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int firstDayWeekday = month.weekday;
    final int emptySlotsBefore = firstDayWeekday - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNight ? const Color(0xFF232527) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isNight ? 0.45 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 4),
            child: Text(
              "${month.year}年${month.month}月",
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                fontFamily: 'LXGWWenKai',
                color: isNight ? Colors.white.withOpacity(0.9) : const Color(0xFF2C2E30),
              ),
            ),
          ),

          ValueListenableBuilder<List<DiaryEntry>>(
            valueListenable: UserState().savedDiaries,
            builder: (context, allDiaries, _) {
              final Map<String, List<DiaryEntry>> dayMap = {};
              final monthDiaries = <DiaryEntry>[];
              
              for (var entry in allDiaries) {
                if (entry.dateTime.year == month.year && entry.dateTime.month == month.month) {
                  monthDiaries.add(entry);
                }
                final key = "${entry.dateTime.year}-${entry.dateTime.month}-${entry.dateTime.day}";
                dayMap.putIfAbsent(key, () => []).add(entry);
              }

              final activeDays = monthDiaries.map((e) => "${e.dateTime.year}-${e.dateTime.month}-${e.dateTime.day}").toSet().length;
              int totalWords = 0;
              for (var e in monthDiaries) {
                totalWords += e.content.length;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: daysInMonth + emptySlotsBefore,
                    itemBuilder: (context, index) {
                      if (index < emptySlotsBefore) return const SizedBox.shrink();

                      final int day = index - emptySlotsBefore + 1;
                      final dateKey = "${month.year}-${month.month}-$day";
                      final entries = dayMap[dateKey];
                      final bool isToday = DateTime.now().year == month.year &&
                          DateTime.now().month == month.month &&
                          DateTime.now().day == day;

                      return _CalendarDayCell(
                        day: day,
                        entries: entries,
                        isToday: isToday,
                        isNight: isNight,
                        onTap: () => onDateSelected(DateTime(month.year, month.month, day)),
                      );
                    },
                  ),

                  if (monthDiaries.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 18, right: 4),
                      child: Text(
                        "$activeDays天 | ${monthDiaries.length}篇 | $totalWords字",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isNight ? Colors.white24 : Colors.black.withOpacity(0.12),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(delay: (index * 80).ms, duration: 400.ms)
    .moveX(begin: 12, end: 0); // 对标主列表的入场动画
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int day;
  final List<DiaryEntry>? entries;
  final bool isToday;
  final bool isNight;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    this.entries,
    required this.isToday,
    required this.isNight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasEntry = entries != null && entries!.isNotEmpty;
    String? thumbPath;
    int? moodIdx;

    if (hasEntry) {
      final latest = entries!.last;
      for (var block in latest.blocks) {
        if (block['type'] == 'image') {
          thumbPath = block['path'];
          break;
        }
      }
      if (thumbPath == null) {
        moodIdx = latest.moodIndex;
      }
    }

    final TextStyle dayStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w900,
      fontFamily: 'LXGWWenKai',
      color: hasEntry 
          ? Colors.white 
          : (isNight ? Colors.white.withOpacity(0.85) : const Color(0xFF2C2E30)),
      shadows: hasEntry ? [
        const Shadow(
          blurRadius: 4,
          color: Colors.black87,
          offset: Offset(0, 1.5),
        )
      ] : null,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isToday 
              ? const Color(0xFFD4A373).withOpacity(isNight ? 0.3 : 0.1)
              : (hasEntry 
                  ? (isNight ? const Color(0xFF3B3E42) : Colors.white)
                  : (isNight ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.008))),
          borderRadius: BorderRadius.circular(10),
          border: isToday 
              ? Border.all(color: const Color(0xFFD4A373), width: 2.2)
              : (hasEntry 
                  ? Border.all(color: isNight ? Colors.white12 : Colors.black.withOpacity(0.12), width: 1.0)
                  : Border.all(color: isNight ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03), width: 0.5)),
          boxShadow: hasEntry ? [
            BoxShadow(
              color: Colors.black.withOpacity(isNight ? 0.45 : 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ] : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (thumbPath != null)
              Positioned.fill(
                child: DiaryUtils.buildImage(
                  thumbPath,
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
            
            if (thumbPath == null && moodIdx != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(
                    kMoods[moodIdx.clamp(0, kMoods.length - 1)].iconPath!,
                    width: 32,
                    height: 32,
                    opacity: const AlwaysStoppedAnimation(0.8),
                  ),
                ),
              ),

            if (hasEntry)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.12),
                ),
              ),

            Center(
              child: Text("$day", style: dayStyle),
            ),

            if (hasEntry && entries!.length > 1)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4A373),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
