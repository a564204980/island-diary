import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 引入 flutter_animate
import 'package:lunar/lunar.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

/// 日历网格面板 V6：动效同步版
class DiaryCalendarPanel extends StatefulWidget {
  final bool isNight;
  final Function(DateTime) onDateSelected;

  const DiaryCalendarPanel({
    super.key,
    required this.isNight,
    required this.onDateSelected,
    this.onShareMonth,
  });

  final Function(DateTime)? onShareMonth;

  @override
  State<DiaryCalendarPanel> createState() => _DiaryCalendarPanelState();
}

class _DiaryCalendarPanelState extends State<DiaryCalendarPanel> {
  final ScrollController _scrollController = ScrollController();
  final DateTime _now = DateTime.now();
  int _loadedMonths = 2; // 极致优化：首屏只计算和渲染 2 个月份（刚好填满手机屏幕），彻底消除耗时

  @override
  void initState() {
    super.initState();

    // 监听滚动，如果滚动到底部附近，再慢慢加载更前面的月份
    _scrollController.addListener(() {
      if (!mounted) return;
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 800) {
        if (_loadedMonths < 36) {
          // 总共大约看 3 年 (36个月)
          setState(() {
            // 每次追加加载 4 个月
            _loadedMonths = (_loadedMonths + 4).clamp(0, 36);
          });
        }
      }
    });
  }

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
    return ValueListenableBuilder<List<DiaryEntry>>(
      valueListenable: UserState().savedDiaries,
      builder: (context, allDiaries, _) {
        // 计算最早记录月份距离当前的总月数，以限制日历无限往回滚
        int maxMonths = 1;
        if (allDiaries.isNotEmpty) {
          DateTime earliest = allDiaries.first.dateTime;
          for (var d in allDiaries) {
            if (d.dateTime.isBefore(earliest)) {
              earliest = d.dateTime;
            }
          }
          final monthDiff =
              (_now.year - earliest.year) * 12 +
              (_now.month - earliest.month) +
              1;
          // 最多展示到最早记录的那个月（且至少展示当月）
          maxMonths = monthDiff > 0 ? monthDiff : 1;
        }

        // 全局 O(N) 预处理，按月份分组，避免在每个子组件里重复遍历百千条数据
        final Map<String, List<DiaryEntry>> monthMap = {};
        for (var d in allDiaries) {
          final k = "${d.dateTime.year}-${d.dateTime.month}";
          monthMap.putIfAbsent(k, () => []).add(d);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 700;
            final int crossAxisCount = isWide ? 2 : 1;

            final int calculatedItemCount = _loadedMonths < maxMonths
                ? _loadedMonths
                : maxMonths;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 16, bottom: 80),
                itemCount: (calculatedItemCount / crossAxisCount).ceil(),
                itemBuilder: (context, rowIndex) {
                  final List<Widget> rowChildren = [];
                  for (int i = 0; i < crossAxisCount; i++) {
                    final index = rowIndex * crossAxisCount + i;
                    if (index < calculatedItemCount) {
                      final month = _getMonthForIndex(index);
                      final k = "${month.year}-${month.month}";
                      final monthDiaries = monthMap[k] ?? [];

                      rowChildren.add(
                        Expanded(
                          child: _MonthSection(
                            index: index,
                            month: month,
                            isNight: widget.isNight,
                            onDateSelected: widget.onDateSelected,
                            onShareMonth: widget.onShareMonth,
                            showWeekdayHeader: true,
                            monthDiaries: monthDiaries,
                          ),
                        ),
                      );
                    } else {
                      rowChildren.add(const Expanded(child: SizedBox.shrink()));
                    }

                    if (i < crossAxisCount - 1) {
                      rowChildren.add(const SizedBox(width: 8));
                    }
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rowChildren,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _MonthSection extends StatelessWidget {
  final int index;
  final DateTime month;
  final bool isNight;
  final Function(DateTime) onDateSelected;
  final bool showWeekdayHeader;
  final List<DiaryEntry> monthDiaries;

  const _MonthSection({
    required this.index,
    required this.month,
    required this.isNight,
    required this.onDateSelected,
    required this.monthDiaries,
    this.onShareMonth,
    this.showWeekdayHeader = false,
  });

  final Function(DateTime)? onShareMonth;

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
                color: Colors.black.withValues(alpha: isNight ? 0.45 : 0.12),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${month.year}年${month.month}月",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'LXGWWenKai',
                        color: isNight
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF2C2E30),
                      ),
                    ),
                    if (onShareMonth != null)
                      GestureDetector(
                        onTap: () => onShareMonth!(month),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.ios_share_rounded,
                            size: 19,
                            color: isNight
                                ? Colors.white24
                                : Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (showWeekdayHeader) ...[
                _buildInternalWeekRow(isNight),
                const SizedBox(height: 12),
              ],

              Builder(
                builder: (context) {
                  // 局部聚合：将该月的数据按“天数 (int)”分组，O(K) 极速操作
                  final Map<int, List<DiaryEntry>> dayMap = {};
                  final Set<int> activeDaysSet = {};
                  int totalWords = 0;

                  for (var entry in monthDiaries) {
                    final d = entry.dateTime.day;
                    dayMap.putIfAbsent(d, () => []).add(entry);
                    activeDaysSet.add(d);
                    totalWords += entry.content.length;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.82,
                            ),
                        itemCount: daysInMonth + emptySlotsBefore,
                        itemBuilder: (context, index) {
                          if (index < emptySlotsBefore)
                            return const SizedBox.shrink();

                          final int day = index - emptySlotsBefore + 1;
                          final entries = dayMap[day];
                          final bool isToday =
                              DateTime.now().year == month.year &&
                              DateTime.now().month == month.month &&
                              DateTime.now().day == day;

                          return _CalendarDayCell(
                            date: DateTime(month.year, month.month, day),
                            entries: entries,
                            isToday: isToday,
                            isNight: isNight,
                            onTap: () => onDateSelected(
                              DateTime(month.year, month.month, day),
                            ),
                          );
                        },
                      ),

                      if (monthDiaries.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 18, right: 4),
                          child: Text(
                            "${activeDaysSet.length}天 | ${monthDiaries.length}篇 | ${totalWords}字",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isNight
                                  ? Colors.white24
                                  : Colors.black.withValues(alpha: 0.12),
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
        // 动画明显提速，进场更干脆，不拖泥带水
        .fadeIn(delay: ((index % 2) * 40).ms, duration: 200.ms)
        .moveX(begin: 8, end: 0);
  }

  Widget _buildInternalWeekRow(bool isNight) {
    final List<String> weekDays = ["一", "二", "三", "四", "五", "六", "日"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 12, // 内部表头稍小一点
                    fontWeight: FontWeight.w800,
                    color: isNight
                        ? Colors.white24
                        : Colors.black.withValues(alpha: 0.12),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final List<DiaryEntry>? entries;
  final bool isToday;
  final bool isNight;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    this.entries,
    required this.isToday,
    required this.isNight,
    required this.onTap,
  });

  // 节日白名单：仅显示核心重要节日，精简视觉噪音
  static const Set<String> _importantFests = {
    '元旦',
    '除夕',
    '春节',
    '元宵节',
    '清明',
    '劳动节',
    '端午节',
    '中秋节',
    '国庆节',
    '情人节',
    '妇女节',
    '儿童节',
    '教师节',
    '圣诞节',
    '冬至',
    '七夕',
    '重阳',
    '腊八',
  };

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

    // 阴历与节假日计算
    String lunarStr = '';
    final lunar = Lunar.fromDate(date);
    final solar = Solar.fromDate(date);

    final solarFests = solar.getFestivals();
    final lunarFests = lunar.getFestivals();
    final jieQi = lunar.getJieQi();

    // 检查是否包含重要节日 (支持部分匹配，如 "国庆节" 匹配 "国庆假期")
    String? importantFest;
    for (final f in [
      ...solarFests,
      ...lunarFests,
      if (jieQi.isNotEmpty) jieQi,
    ]) {
      if (_importantFests.any((important) => f.contains(important))) {
        importantFest = _importantFests.firstWhere(
          (important) => f.contains(important),
        );
        break;
      }
    }

    if (importantFest != null) {
      lunarStr = importantFest;
    } else {
      if (lunar.getDay() == 1) {
        lunarStr = '${lunar.getMonthInChinese()}月';
      } else {
        lunarStr = lunar.getDayInChinese();
      }
    }

    final TextStyle dayStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w900,
      fontFamily: 'LXGWWenKai',
      color: hasEntry
          ? Colors.white
          : (isNight
                ? Colors.white.withValues(alpha: 0.85)
                : const Color(0xFF2C2E30)),
      shadows: hasEntry
          ? [
              const Shadow(
                blurRadius: 4,
                color: Colors.black87,
                offset: Offset(0, 1.5),
              ),
            ]
          : null,
    );

    final Color lunarColor = (importantFest != null)
        ? (hasEntry ? Colors.white : const Color(0xFFD4A373)) // 仅重要节日用亮色
        : (isNight ? Colors.white30 : Colors.black38); // 普通农历用淡色

    final TextStyle lunarStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w600,
      fontFamily: 'LXGWWenKai',
      color: hasEntry ? Colors.white70 : lunarColor,
      shadows: hasEntry
          ? [
              const Shadow(
                blurRadius: 3,
                color: Colors.black54,
                offset: Offset(0, 1),
              ),
            ]
          : null,
      height: 1.1,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isToday
              ? const Color(0xFFD4A373).withValues(alpha: isNight ? 0.3 : 0.1)
              : (hasEntry
                    ? (isNight ? const Color(0xFF3B3E42) : Colors.white)
                    : (isNight
                          ? Colors.white.withValues(alpha: 0.02)
                          : Colors.black.withValues(alpha: 0.008))),
          borderRadius: BorderRadius.circular(10),
          border: isToday
              ? Border.all(color: const Color(0xFFD4A373), width: 2.2)
              : (hasEntry
                    ? Border.all(
                        color: isNight
                            ? Colors.white12
                            : Colors.black.withValues(alpha: 0.12),
                        width: 1.0,
                      )
                    : Border.all(
                        color: isNight
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03),
                        width: 0.5,
                      )),
          boxShadow: hasEntry
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isNight ? 0.45 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
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
                child: Container(color: Colors.black.withValues(alpha: 0.12)),
              ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${date.day}", style: dayStyle),
                  const SizedBox(height: 1),
                  Text(lunarStr, style: lunarStyle),
                ],
              ),
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
